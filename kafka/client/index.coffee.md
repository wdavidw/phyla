
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports =
      use:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hdp: module: 'ryba/hdp', local: true
        hdf: module: 'ryba/hdf', local: true
        zookeeper_server: module: 'ryba/zookeeper/server', required: true
        kafka_broker: module: 'ryba/kafka/broker', required: true
      configure: 'ryba/kafka/client/configure'
      commands:
        install: ->
          options = @config.ryba.kafka.client
          @call 'ryba/kafka/client/install', options
          @call 'ryba/kafka/client/check', options
        check: ->
          options = @config.ryba.kafka.client
          @call 'ryba/kafka/client/check', options
