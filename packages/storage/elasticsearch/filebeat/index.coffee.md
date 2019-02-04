
# Filebeat

[Filebeat](https://www.elastic.co/products/beats/filebeat) Filebeat helps you keep the simple things simple by offering a lightweight way to forward and centralize logs and files.

    module.exports =
      deps:
        java: implicit: true, module: 'masson/commons/java'
        logstash: module: '@rybajs/storage/elasticsearch/logstash', only: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn', local: true
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn', local: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm', local: true
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm', local: true
        hive_server2: module: '@rybajs/metal/hive/server2', local: true
        hive_webhcat: module: '@rybajs/metal/hive/webhcat', local: true
        oozie_server: module: '@rybajs/metal/oozie/server', local: true
        hbase_rest: module: '@rybajs/metal/hbase/rest', local: true
        hbase_master: module: '@rybajs/metal/hbase/master', local: true
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver', local: true
        nifi: module: '@rybajs/metal/nifi', local: true
        kafka: module: '@rybajs/metal/kafka/broker', local: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', local: true
        knox: module: '@rybajs/metal/knox/server', local: true
        zookeeper: module: '@rybajs/metal/zookeeper/server', local: true
      configure:
        '@rybajs/storage/elasticsearch/filebeat/configure'
      commands:
        'prepare':
          '@rybajs/storage/elasticsearch/filebeat/prepare'
        'install': [
          '@rybajs/storage/elasticsearch/filebeat/install'
          '@rybajs/storage/elasticsearch/filebeat/start'
        ]
        'start':
          '@rybajs/storage/elasticsearch/filebeat/start'
        'status':
          '@rybajs/storage/elasticsearch/filebeat/status'
        'stop':
          '@rybajs/storage/elasticsearch/filebeat/stop'
