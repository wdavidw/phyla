
# Kafka Consumer

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        hdp: module: '@rybajs/metal/hdp', local: true
        hdf: module: '@rybajs/metal/hdf', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server', required: true
        kafka_broker: module: '@rybajs/metal/kafka/broker', required: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        ranger_kafka: module: '@rybajs/metal/ranger/plugins/kafka'
      configure: '@rybajs/metal/kafka/client/configure'
      commands:
        install: [
          '@rybajs/metal/kafka/client/install'
          '@rybajs/metal/kafka/client/check'
        ]
        check:
          '@rybajs/metal/kafka/client/check'
