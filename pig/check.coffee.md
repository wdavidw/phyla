
# Pig Check

    module.exports = header: 'Pig Check', handler: ->
      {force_check, user} = @config.ryba

## Wait

      @call once: true, 'ryba/hadoop/yarn_rm/wait'

## Pig Script

Run a Pig script to test the installation once the ResourceManager is
installed. The script will only be executed the first time it is deployed
unless the "hdp.force_check" configuration property is set to "true".

      @call header: 'Pig Check Client', ->
        @file
          content: """
          data = LOAD '/user/#{user.name}/#{@config.shortname}-pig_tmp/data' USING PigStorage(',') AS (text, number);
          result = foreach data generate UPPER(text), number+2;
          STORE result INTO '/user/#{user.name}/#{@config.shortname}-pig' USING PigStorage();
          """
          target: '/tmp/ryba-test.pig'
        @system.execute
          cmd: mkcmd.test @, """
          hdfs dfs -rm -r -skipTrash #{@config.shortname}-pig_tmp || true
          hdfs dfs -rm -r -skipTrash #{@config.shortname}-pig || true
          hdfs dfs -mkdir -p #{@config.shortname}-pig_tmp
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{@config.shortname}-pig_tmp/data
          pig /tmp/ryba-test.pig
          hdfs dfs -test -d /user/#{user.name}/#{@config.shortname}-pig
          """
          unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -d #{@config.shortname}-pig"
          trap: true

## HCat

      @call header: 'Pig Check HCat', ->
        query = (query) -> "hcat -e \"#{query}\" "
        db = "check_#{@config.shortname}_pig_hcat"
        @file
          content: """
          data = LOAD '#{db}.check_tb' USING org.apache.hive.hcatalog.pig.HCatLoader();
          agroup = GROUP data ALL;
          asum = foreach agroup GENERATE SUM(data.col2);
          STORE asum INTO '/user/#{user.name}/#{@config.shortname}-pig_hcat' USING PigStorage();
          """
          target: "/tmp/ryba-pig_hcat.pig"
          eof: true
        @system.execute
          cmd: mkcmd.test @, """
          hdfs dfs -rm -r #{@config.shortname}-pig_hcat_tmp || true
          hdfs dfs -rm -r #{@config.shortname}-pig_hcat || true
          hdfs dfs -mkdir -p #{@config.shortname}-pig_hcat_tmp/db/check_tb
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{@config.shortname}-pig_hcat_tmp/db/check_tb/data
          #{query "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{user.name}/#{@config.shortname}-pig_hcat_tmp/db';"}
          #{query "CREATE TABLE IF NOT EXISTS #{db}.check_tb(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"}
          pig -useHCatalog /tmp/ryba-pig_hcat.pig
          #{query "DROP TABLE #{db}.check_tb;"}
          #{query "DROP DATABASE #{db};"}
          hdfs dfs -rm -r #{@config.shortname}-pig_hcat_tmp
          hdfs dfs -test -d #{@config.shortname}-pig_hcat
          """
          unless_exec: unless force_check then mkcmd.test @, "hdfs dfs -test -d #{@config.shortname}-pig_hcat"
          trap: true

## Dependencies

    mkcmd = require '../lib/mkcmd'
