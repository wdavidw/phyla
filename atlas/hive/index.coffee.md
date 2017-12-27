
# Apache Atlas Hive Plugin

This service must be collocated with the Hive Server2. Also, it required an 
Atlas server to be active.

    module.exports =
      deps:
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        kafka_broker: module: 'ryba/kafka/broker', reguired: true
        hive_server2: module: 'ryba/hive/server2', local: true, required: true
        oozie_server: module: 'ryba/oozie/server'
        atlas: module: 'ryba/atlas'
      configure:
        'ryba/atlas/hive/configure'
      plugin: (options) ->
        delete options.original.type
        delete options.original.handler
        delete options.original.argument
        delete options.original.store
        @before
          type: ['service','start']
          name: 'hive-server2'
        , ->
          @call 'ryba/atlas/hive/install', options.original
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

[atlas-apache]: http://atlas.incubator.apache.org
