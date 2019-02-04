# Ranger Kafka Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        kafka_broker: module: '@rybajs/metal/kafka/broker', local: true, required: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true, required: true
        ranger_hdfs: module: '@rybajs/metal/ranger/plugins/hdfs', required: true
        ranger_kafka: module: '@rybajs/metal/ranger/plugins/kafka'
      configure:
        '@rybajs/metal/ranger/plugins/kafka/configure'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'kafka-broker'
        , ->
          @call '@rybajs/metal/ranger/plugins/kafka/install', options
        # @after '@rybajs/metal/kafka/broker/install', ->
        #   @call '@rybajs/metal/ranger/plugins/kafka/install', options
