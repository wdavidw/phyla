
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
        # repo: module: '@rybajs/storage/mongodb/repo'
        config_servers: module: '@rybajs/storage/mongodb/configsrv'
      configure:
        '@rybajs/storage/mongodb/configsrv/configure'
      commands:
        'check':
          '@rybajs/storage/mongodb/configsrv/check'
        'install': [
          '@rybajs/storage/mongodb/configsrv/install'
          '@rybajs/storage/mongodb/configsrv/start'
          '@rybajs/storage/mongodb/configsrv/wait'
          '@rybajs/storage/mongodb/configsrv/replication'
          '@rybajs/storage/mongodb/configsrv/check'
        ]
        'start':
          '@rybajs/storage/mongodb/configsrv/start'
        'stop':
          '@rybajs/storage/mongodb/configsrv/stop'
        'status':
          '@rybajs/storage/mongodb/configsrv/status'
