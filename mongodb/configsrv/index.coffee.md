
# MongoDB Config Server (Distributed)

MongoDB is a document-oriented database. Distributed Version.

Config servers are special mongod instances that store the metadata for a
sharded cluster.
All config servers must be available to deploy a sharded cluster or to make any
changes to cluster metadata.

    module.exports =
      deps:
        locale: module: 'masson/core/locale', local: true, auto: true, implicit: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        ssl: module: 'masson/core/ssl', local: true
        # repo: module: 'ryba/mongodb/repo'
        config_servers: module: 'ryba/mongodb/configsrv'
      configure:
        'ryba/mongodb/configsrv/configure'
      commands:
        'check':
          'ryba/mongodb/configsrv/check'
        'install': [
          'ryba/mongodb/configsrv/install'
          'ryba/mongodb/configsrv/start'
          'ryba/mongodb/configsrv/wait'
          'ryba/mongodb/configsrv/replication'
          'ryba/mongodb/configsrv/check'
        ]
        'start':
          'ryba/mongodb/configsrv/start'
        'stop':
          'ryba/mongodb/configsrv/stop'
        'status':
          'ryba/mongodb/configsrv/status'
