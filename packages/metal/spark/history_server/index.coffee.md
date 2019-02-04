
# Spark History Server

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hdfs_client: '@rybajs/metal/hadoop/hdfs_client'
        iptables: module: 'masson/core/iptables', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true
        spark_client: '@rybajs/metal/spark/client'
        spark_history: '@rybajs/metal/spark/client'
      configure:
        '@rybajs/metal/spark/history_server/configure'
      commands:
        'install': [
          '@rybajs/metal/spark/history_server/install'
          '@rybajs/metal/spark/history_server/start'
          '@rybajs/metal/spark/history_server/check'
        ]
        'start':
          '@rybajs/metal/spark/history_server/start'
        'stop':
          '@rybajs/metal/spark/history_server/stop'
        'check':
          '@rybajs/metal/spark/history_server/check'
