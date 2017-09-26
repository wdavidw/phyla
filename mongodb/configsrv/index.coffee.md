
# MongoDB Config Server (Distributed)

MongoDB is a document-oriented database. Distributed Version.

Config servers are special mongod instances that store the metadata for a
sharded cluster.
All config servers must be available to deploy a sharded cluster or to make any
changes to cluster metadata.

    module.exports =
      use:
        locale: module: 'masson/core/locale', local: true, auto: true, implicit: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        ssl: module: 'masson/core/ssl', local: true
        repo: module: 'ryba/mongodb/repo'
        config_servers: module: 'ryba/mongodb/configsrv'
      configure:
        'ryba/mongodb/configsrv/configure'
      commands:
        'check': ->
          options = @config.ryba.mongodb.configsrv
          @call 'ryba/mongodb/configsrv/check', options
        'install': ->
          options = @config.ryba.mongodb.configsrv
          @call 'ryba/mongodb/configsrv/install', options
          @call 'ryba/mongodb/configsrv/start', options
          @call 'ryba/mongodb/configsrv/wait', options
          @call 'ryba/mongodb/configsrv/replication', options
          @call 'ryba/mongodb/configsrv/check', options
        'start': ->
          options = @config.ryba.mongodb.configsrv
          @call 'ryba/mongodb/configsrv/start', options
        'stop': ->
          options = @config.ryba.mongodb.configsrv
          @call 'ryba/mongodb/configsrv/stop', options
        'status': ->
          options = @config.ryba.mongodb.configsrv
          @call 'ryba/mongodb/configsrv/status', options
