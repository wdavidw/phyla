
# Hive Beeline (Server2 Client)

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hcat: module: 'ryba/hive/hcatalog'
        server2: module: 'ryba/hive/server2'
        ranger_admin: module: 'ryba/ranger/admin'
        spark_thrift_servers: module: 'ryba/spark/thrift_server'
      configure:
        'ryba/hive/beeline/configure'
      commands:
        'install': [
          'ryba/hive/beeline/install'
          'ryba/hive/beeline/check'
        ]
        'check':
          'ryba/hive/beeline/check'
