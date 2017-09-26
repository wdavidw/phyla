
# MongoDB Config Server (Distributed)

MongoDB is a document-oriented database. Distributed Version.

Config servers are special mongod instances that store the metadata for a
sharded cluster.
All config servers must be available to deploy a sharded cluster or to make any
changes to cluster metadata.

    module.exports =
      use:
        locale: implicit: true, module: 'masson/core/locale'
        iptables: implicit: true, module: 'masson/core/iptables'
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        ssl: module: 'masson/core/ssl', local: true
        repo: 'ryba/mongodb/repo'
        config_servers: 'ryba/mongodb/configsrv'
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
