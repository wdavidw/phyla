
# Apache Atlas Hive Plugin

This service must be collocated with the Hive Server2. Also, it required an 
Atlas server to be active.

    module.exports =
      use:
        kafka_broker: module: 'ryba/kafka/broker', requried: true
        hive_server2: module: 'ryba/hive/server2', local: true, required: true
        atlas: module: 'ryba/atlas', required: true
      configure:
        'ryba/atlas/hive/configure'
      plugin: ->
        options = @config.ryba.atlas.hive
        @before
          type: ['service','start']
          name: 'hive-server2'
        , ->
          @registry.register 'hdp_select', 'ryba/lib/hdp_select'
          @service 'atlas-metadata*hive-plugin*'
          @hdp_select 'atlas-client' #needed by hive server2 aux jars
        @after
          type: ['hconfigure']
          target: "#{options.conf_dir}/hive-site.xml"
        , ->
          @file.properties
            header: 'Atlas Client Properties'
            target: '/etc/hive/conf/client.properties'
            content: options.client.properties
          @file.properties
            header: 'Atlas Hiveserver2 Client Properties'
            target: "#{options.conf_dir}/client.properties"
            content: options.client.properties
          @file.properties
            header: 'Atlas Hiveserver2 Application Properties'
            target: "#{options.conf_dir}/atlas-application.properties"
            content: options.application.properties
        @before
          type: ['service', 'start']
          name: 'hadoop-hdfs-namenode'
        , ->
          @call 'ryba/ranger/plugins/hdfs/install', options
        

[atlas-apache]: http://atlas.incubator.apache.org
