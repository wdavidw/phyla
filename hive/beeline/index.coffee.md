
# Hive Beeline (Server2 Client)

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client'
        java: implicit: true, module: 'masson/commons/java'
        hcat: 'ryba/hive/hcatalog'
        server2: 'ryba/hive/server2'
        ranger_admin: 'ryba/ranger/admin'
        spark_thrift_servers: 'ryba/spark/thrift_server'
      configure:
        'ryba/hive/beeline/configure'
      commands:
        'install': [
          'ryba/hive/beeline/install'
          'ryba/hive/beeline/check'
        ]
        'check':
          'ryba/hive/beeline/check'
