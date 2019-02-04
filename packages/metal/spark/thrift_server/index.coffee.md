
# Spark SQL Thrift Server

Spark SQL is a Spark module for structured data processing. 
Unlike the basic Spark RDD API, the interfaces provided by Spark SQL provide Spark 
with more information about the structure of both the data and the computation being performed. 
It starts a custom instance of hive-sever2 and enabled user to register spark based table
in order to make the data accessible to hive clients.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true, auto: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true
        hdfs: module: '@rybajs/metal/hadoop/hdfs_client'
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn', required: true
        hive_server2: module: '@rybajs/metal/hive/server2'
        spark_client: module: '@rybajs/metal/spark/client', local: true, auto: true
        spark_thrift_server: module: '@rybajs/metal/spark/thrift_server'
        yarn_nm: '@rybajs/metal/hadoop/yarn_nm'
        tez: module: '@rybajs/metal/tez', local: true
      configure :
        '@rybajs/metal/spark/thrift_server/configure'
      commands:
        'install': [
          '@rybajs/metal/spark/thrift_server/install'
          '@rybajs/metal/spark/thrift_server/start'
          '@rybajs/metal/spark/thrift_server/check'
        ]
        'check':
          '@rybajs/metal/spark/thrift_server/check'
        'stop':
          '@rybajs/metal/spark/thrift_server/stop'
        'start':
          '@rybajs/metal/spark/thrift_server/start'
