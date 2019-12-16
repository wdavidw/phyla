
# Apache Atlas Hive Plugin

This service must be collocated with the Hive Server2. Also, it required an 
Atlas server to be active.

    module.exports =
      deps:
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        kafka_broker: module: '@rybajs/metal/kafka/broker', reguired: true
        hive_server2: module: '@rybajs/metal/hive/server2', local: true, required: true
        oozie_server: module: '@rybajs/metal/oozie/server'
        atlas: module: '@rybajs/metal/atlas'
      configure:
        '@rybajs/metal/atlas/hive/configure'
      commands:
        install: '@rybajs/metal/atlas/hive/install'
      plugin: ({options}) ->
        @before
          action: ['service','start']
          name: 'hive-server2'
        , ->
          @call '@rybajs/metal/atlas/hive/install', options.original
        @after
          action: ['file', 'types', 'hfile']
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
