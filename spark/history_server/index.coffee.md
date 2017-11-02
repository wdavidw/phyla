
# Spark History Server

    module.exports =
      use:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hdfs_client: 'ryba/hadoop/hdfs_client'
        iptables: module: 'masson/core/iptables', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
        spark_client: 'ryba/spark/client'
        spark_history: 'ryba/spark/client'
      configure:
        'ryba/spark/history_server/configure'
      commands:
        'install': ->
          options = @config.ryba.spark.history_server
          @call 'ryba/spark/history_server/install', options
          @call 'ryba/spark/history_server/start', options
          @call 'ryba/spark/history_server/check', options
        'start': ->
          options = @config.ryba.spark.history_server
          @call 'ryba/spark/history_server/start', options
        'stop': ->
          options = @config.ryba.spark.history_server
          @call 'ryba/spark/history_server/stop', options
        'check': ->
          options = @config.ryba.spark.history_server
          @call 'ryba/spark/history_server/check', options
