
# Hive Beeline (Server2 Client)

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        hive_hcatalog: module: '@rybajs/metal/hive/hcatalog', required: true
        hive_server2: module: '@rybajs/metal/hive/server2', required: true
        spark_thrift_server: module: '@rybajs/metal/spark2/thrift_server'
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        ranger_hive: module: '@rybajs/metal/ranger/plugins/hiveserver2'
        ranger_hdfs: module: '@rybajs/metal/ranger/plugins/hdfs'
      configure:
        '@rybajs/metal/hive/beeline/configure'
      commands:
        'install': [
          '@rybajs/metal/hive/beeline/install'
          '@rybajs/metal/hive/beeline/check'
        ]
        'check':
          '@rybajs/metal/hive/beeline/check'
