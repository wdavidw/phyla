
# Kafka Broker

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hdp: module: 'ryba/hdp', local: true
        hdf: module: 'ryba/hdf', local: true
        zookeeper_server: module: 'ryba/zookeeper/server', required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        kafka_broker: module: 'ryba/kafka/broker'
        ranger_admin: module: 'ryba/ranger/admin'
        metrics: module: 'ryba/metrics', local: true
        log4j: module: 'ryba/log4j', local: true
      configure:
        'ryba/kafka/broker/configure'
      commands:
        'install': [
          'ryba/kafka/broker/install'
          'ryba/kafka/broker/start'
          'ryba/kafka/broker/check'
        ]
        'check':
          'ryba/kafka/broker/check'
        'start':
          'ryba/kafka/broker/start'
        'stop':
          'ryba/kafka/broker/stop'
        'status':
          'ryba/kafka/broker/status'
