
# Solr Install

    module.exports = header: 'Solr Cloud Check', handler: (options) ->
      protocol = if options.ssl.enabled then 'https' else 'http'

## Wait
Wait for zookeeper, and solr servers

      @call '@rybajs/metal/zookeeper/server/wait', once: true, options.wait_krb5_client
      @call '@rybajs/metal/solr/cloud/wait', once: true, options.wait
      @registry.register 'hdfs_mkdir', '@rybajs/metal/lib/hdfs_mkdir'

## Create Collection with HDFS based index
This check is inspired [from HDP][search-hdp].
TODO: April 2016: hadoop connector not taking in count -zk params.
Check if hadoop connector works and re-activate jar execution.

      @call header: 'Create Collection (HDFS)', if: options.hdfs?, ->
        collection = check_dir = "ryba-check-solr-hdfs-#{options.hostname}"
        @system.execute
          if: options.force_check
          cmd: mkcmd.solr, """
          rm -rf /tmp/#{check_dir} || true
          #{options.latest_dir}/bin/solr delete -c #{collection} || true
          hadoop fs -rm  -r /user/#{options.user.name}/csv || true
          zookeeper-client -server #{options.zk_connect} rmr #{options.zk_node}/configs/#{collection}
          """
        @call
          unless_exec:unless options.force_check then "test -f /tmp/#{check_dir}/checked"
        , ->
          @system.execute
            cmd: "cp -R #{options.latest_dir}/server/solr/configsets/data_driven_schema_configs /tmp/#{check_dir}"
          @file.render
            header: 'Solrconfig'
            source: "#{__dirname}/../resources/cloud/solrconfig.xml.j2"
            target: "/tmp/#{check_dir}/solrconfig.xml"
            local: true
            context: options
            eof: true
          @system.execute
            cmd: """
            su -l solr -c " #{options.latest_dir}/bin/solr create_collection -c #{collection} \
              -d /tmp/#{check_dir}/conf -shards #{options.shards} "
            """
            unless_exec: "#{options.latest_dir}/bin/solr healthcheck -c #{collection} -z #{options.zk_connect}#{options.zk_node} | grep '\"status\":\"healthy\"'"
          @system.execute
            if: false
            cmd: mkcmd.solr, """
            set -e
            hadoop fs -mkdir -p /user/#{options.user.name}/csv
            hadoop fs -put #{options.latest_dir}/example/exampledocs/books.csv /user/#{options.user.name}/csv/
            hadoop jar #{path.dirname options.latest_dir}/job/lucidworks-hadoop-job-2.0.3.jar \
            com.lucidworks.hadoop.ingest.IngestJob \
            -DcsvFieldMapping=0=id,1=cat,2=name,3=price,4=instock,5=author \
            -DcsvFirstLineComment -DidField=id -DcsvDelimiter="," \
            -Dlww.commit.on.close=true -cls com.lucidworks.hadoop.ingest.CSVIngestMapper \
            -c #{collection} -i /user/#{options.user.name}/csv/* -of com.lucidworks.hadoop.io.LWMapRedOutputFormat -zk #{options.zk_connect}#{options.zk_node}
            """
          @system.execute
            if: -> @status -2
            cmd: """
            touch /tmp/#{check_dir}/checked
            """

## Create Collection with Local dir based index
This check is inspired [from HDP][search-hdp].

      @call header: 'Create Collection (Local)', ->
        collection = check_dir = "ryba-check-solr-local-#{options.hostname}"
        options.dir_factory = options.user.home
        options.lock_type = 'native'
        @system.execute
          if: options.force_check
          cmd: mkcmd.solr, """
          rm -rf /tmp/#{check_dir} || true
          #{options.latest_dir}/bin/solr delete -c #{collection} || true
          zookeeper-client -server #{options.zk_connect} rmr #{options.zk_node}/configs/#{collection} 2&>1 || true
          """
        @call
          unless_exec: unless options.force_check then "test -f /tmp/#{check_dir}/checked"
        , ->
          @system.execute
            cmd: "cp -R #{options.latest_dir}/server/solr/configsets/data_driven_schema_configs /tmp/#{check_dir}"
          @file.render
            header: 'Solrconfig'
            source: "#{__dirname}/../resources/cloud/solrconfig.xml.j2"
            target: "/tmp/#{check_dir}/solrconfig.xml"
            local: true
            context: options
            eof: true
          @system.execute
            cmd: """
            su -l solr -c "#{options.latest_dir}/bin/solr create_collection -c #{collection} \
              -d /tmp/#{check_dir}/conf -shards #{options.shards} "
            """
            unless_exec: "#{options.latest_dir}/bin/solr healthcheck -c #{collection} -z #{options.zk_connect}#{options.zk_node} | grep '\"status\":\"healthy\"'"
          @system.execute
            if: -> @status -1
            cmd: """
            touch /tmp/#{check_dir}/checked
            """

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    path = require 'path'

[search-hdp]:(http://fr.hortonworks.com/hadoop-tutorial/searching-data-solr/)
