
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true
        hdp: module: 'ryba/hdp', local: true
        hdf: module: 'ryba/hdf', local: true
        zookeeper_server: module: 'ryba/zookeeper/server', required: true
        kafka_broker: module: 'ryba/kafka/broker', required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_kafka: module: 'ryba/ranger/plugins/kafka'
      configure: 'ryba/kafka/client/configure'
      commands:
        install: [
          'ryba/kafka/client/install'
          'ryba/kafka/client/check'
        ]
        check:
          'ryba/kafka/client/check'
