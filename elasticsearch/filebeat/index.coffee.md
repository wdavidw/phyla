
# Filebeat

[Filebeat](https://www.elastic.co/products/beats/filebeat) Filebeat helps you keep the simple things simple by offering a lightweight way to forward and centralize logs and files.

    module.exports =
      deps:
        java: implicit: true, module: 'masson/commons/java'
        logstash: module: 'ryba/elasticsearch/logstash', only: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', local: true
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn', local: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm', local: true
        yarn_nm: module: 'ryba/hadoop/yarn_nm', local: true
        hive_server2: module: 'ryba/hive/server2', local: true
        hive_webhcat: module: 'ryba/hive/webhcat', local: true
        oozie_server: module: 'ryba/oozie/server', local: true
        hbase_rest: module: 'ryba/hbase/rest', local: true
        hbase_master: module: 'ryba/hbase/master', local: true
        hbase_regionserver: module: 'ryba/hbase/regionserver', local: true
        nifi: module: 'ryba/nifi', local: true
        kafka: module: 'ryba/kafka/broker', local: true
        ranger_admin: module: 'ryba/ranger/admin', local: true
        knox: module: 'ryba/knox/server', local: true
        zookeeper: module: 'ryba/zookeeper/server', local: true
      configure:
        'ryba/elasticsearch/filebeat/configure'
      commands:
        'prepare':
          'ryba/elasticsearch/filebeat/prepare'
        'install': [
          'ryba/elasticsearch/filebeat/install'
          'ryba/elasticsearch/filebeat/start'
        ]
        'start':
          'ryba/elasticsearch/filebeat/start'
        'status':
          'ryba/elasticsearch/filebeat/status'
        'stop':
          'ryba/elasticsearch/filebeat/stop'
