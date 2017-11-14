# Ranger Kafka Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        kafka_broker: module: 'ryba/kafka/broker', local: true, required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
        # ranger_hdfs: module: 'ryba/ranger/plugins/hdfs', local: true, required: true
        ranger_kafka: module: 'ryba/ranger/plugins/kafka'
      configure:
        'ryba/ranger/plugins/kafka/configure'
      plugin: (options) ->
        @before
          type: ['service', 'start']
          name: 'kafka-broker'
        , ->
          delete options.original.type
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/ranger/plugins/kafka/install', options.original
        # @after 'ryba/kafka/broker/install', ->
        #   @call 'ryba/ranger/plugins/kafka/install', options
