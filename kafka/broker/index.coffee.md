
# Kafka Broker

Apache Kafka is publish-subscribe messaging rethought as a distributed commit
log. It is fast, scalable, durable and distributed by design.

    module.exports =
      use:
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
      configure:
        'ryba/kafka/broker/configure'
      commands:
        'install': ->
          options = @config.ryba.kafka.broker
          @call 'ryba/kafka/broker/install', options
          @call 'ryba/kafka/broker/start', options
          @call 'ryba/kafka/broker/check', options
        'check': ->
          options = @config.ryba.kafka.broker
          @call 'ryba/kafka/broker/check', options
        'start': ->
          options = @config.ryba.kafka.broker
          @call 'ryba/kafka/broker/start', options
        'stop': ->
          options = @config.ryba.kafka.broker
          @call 'ryba/kafka/broker/stop', options
        'status':
          'ryba/kafka/broker/status'
