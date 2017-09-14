# Ranger Kafka Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        kafka_broker: module: 'ryba/kafka/broker', local: true, required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs', local: true, required: true
        ranger_kafka: module: 'ryba/ranger/plugins/kafka'
      configure:
        'ryba/ranger/plugins/kafka/configure'
