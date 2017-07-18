
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports =
      use:
        kafka_broker: 'ryba/kafka/broker'
        hdf: 'ryba/hdf'
        hdp: 'ryba/hdp'
      configure: 'ryba/kafka/client/configure'
      commands:
        install: ->
            options = @config.ryba.kafka
            @call 'ryba/kafka/client/install', options
            @call 'ryba/kafka/client/check', options
        check:
          'ryba/kafka/client/check'
