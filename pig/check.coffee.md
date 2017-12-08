
# Pig Check

    module.exports = header: 'Pig Check', handler: (options) ->

## Wait

      @call 'ryba/hadoop/yarn_rm/wait', once: true, options.wait_yarn_rm
      @call 'ryba/hive/hcatalog/wait', once: true, options.wait_hive_hcatalog

## Pig Script

Run a Pig script to test the installation once the ResourceManager is
installed. The script will only be executed the first time it is deployed
unless the "force_check" option is set to "true".

      @call header: 'Pig Check Client', ->
        @file
          content: """
          data = LOAD '/user/#{options.test.user.name}/#{options.hostname}-pig_tmp/data' USING PigStorage(',') AS (text, number);
          result = foreach data generate UPPER(text), number+2;
          STORE result INTO '/user/#{options.test.user.name}/#{options.hostname}-pig' USING PigStorage();
          """
          target: '/tmp/ryba-test.pig'
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -rm -r -skipTrash #{options.hostname}-pig_tmp || true
          hdfs dfs -rm -r -skipTrash #{options.hostname}-pig || true
          hdfs dfs -mkdir -p #{options.hostname}-pig_tmp
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{options.hostname}-pig_tmp/data
          pig /tmp/ryba-test.pig
          hdfs dfs -test -d /user/#{options.test.user.name}/#{options.hostname}-pig
          """
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -d #{options.hostname}-pig"
          trap: true

## HCat

      @call header: 'Pig Check HCatalog', ->
        query = (query) -> "hive -e \"#{query}\" "
        db = "check_#{options.hostname}_pig_hcat"
        @file
          content: """
          data = LOAD '#{db}.check_tb' USING org.apache.hive.hcatalog.pig.HCatLoader();
          agroup = GROUP data ALL;
          asum = foreach agroup GENERATE SUM(data.col2);
          STORE asum INTO '/user/#{options.test.user.name}/#{options.hostname}-pig_hcat' USING PigStorage();
          """
          target: "/tmp/ryba-pig_hcat.pig"
          eof: true
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          hdfs dfs -rm -r #{options.hostname}-pig_hcat_tmp || true
          hdfs dfs -rm -r #{options.hostname}-pig_hcat || true
          hdfs dfs -mkdir -p #{options.hostname}-pig_hcat_tmp/db/check_tb
          echo -e 'a,1\\nb,2\\nc,3' | hdfs dfs -put - #{options.hostname}-pig_hcat_tmp/db/check_tb/data
          #{query "CREATE DATABASE IF NOT EXISTS #{db} LOCATION '/user/#{options.test.user.name}/#{options.hostname}-pig_hcat_tmp/db';"}
          #{query "CREATE TABLE IF NOT EXISTS #{db}.check_tb(col1 STRING, col2 INT) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';"}
          pig -useHCatalog /tmp/ryba-pig_hcat.pig
          #{query "DROP TABLE #{db}.check_tb;"}
          #{query "DROP DATABASE #{db};"}
          hdfs dfs -rm -r #{options.hostname}-pig_hcat_tmp
          hdfs dfs -test -d #{options.hostname}-pig_hcat
          """
          unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -d #{options.hostname}-pig_hcat"
          trap: true

## Dependencies

    mkcmd = require '../lib/mkcmd'
