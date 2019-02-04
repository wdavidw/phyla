
# Kafka Broker

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        hdp: module: '@rybajs/metal/hdp', local: true
        hdf: module: '@rybajs/metal/hdf', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server', required: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        kafka_broker: module: '@rybajs/metal/kafka/broker'
        ranger_admin: module: '@rybajs/metal/ranger/admin'
        metrics: module: '@rybajs/metal/metrics', local: true
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/kafka/broker/configure'
      commands:
        'install': [
          '@rybajs/metal/kafka/broker/install'
          '@rybajs/metal/kafka/broker/start'
          '@rybajs/metal/kafka/broker/check'
        ]
        'check':
          '@rybajs/metal/kafka/broker/check'
        'start':
          '@rybajs/metal/kafka/broker/start'
        'stop':
          '@rybajs/metal/kafka/broker/stop'
        'status':
          '@rybajs/metal/kafka/broker/status'
