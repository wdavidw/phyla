
# Spark History Server

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hdfs_client: 'ryba/hadoop/hdfs_client'
        iptables: module: 'masson/core/iptables', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
        spark_client: 'ryba/spark2/client'
        spark_history: 'ryba/spark2/history_server'
      configure:
        'ryba/spark2/history_server/configure'
      commands:
        'install': [
          'ryba/spark2/history_server/install'
          'ryba/spark2/history_server/start'
          'ryba/spark2/history_server/check'
        ]
        'start':
          'ryba/spark2/history_server/start'
        'stop':
          'ryba/spark2/history_server/stop'
        'check':
          'ryba/spark2/history_server/check'
