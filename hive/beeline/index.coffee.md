
# Hive Beeline (Server2 Client)

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hive_hcatalog: module: 'ryba/hive/hcatalog', required: true
        hive_server2: module: 'ryba/hive/server2', required: true
        spark_thrift_server: module: 'ryba/spark2/thrift_server'
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_hive: module: 'ryba/ranger/plugins/hiveserver2'
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs'
      configure:
        'ryba/hive/beeline/configure'
      commands:
        'install': [
          'ryba/hive/beeline/install'
          'ryba/hive/beeline/check'
        ]
        'check':
          'ryba/hive/beeline/check'
