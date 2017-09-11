
# Hive Beeline (Server2 Client)

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hive_hcatalog: module: 'ryba/hive/hcatalog', required: true
        hive_server2: module: 'ryba/hive/server2'
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_hive: module: 'ryba/ranger/plugins/hiveserver2'
        spark_thrift_server: module: 'ryba/spark/thrift_server'
      configure:
        'ryba/hive/beeline/configure'
      commands:
        'install': ->
          options = @config.ryba.hive.beeline
          @call 'ryba/hive/beeline/install', options
          @call 'ryba/hive/beeline/check', options
        'check': ->
          options = @config.ryba.hive.beeline
          @call 'ryba/hive/beeline/check', options
