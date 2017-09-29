
# MongoDB Shard (Distributed)

MongoDB is a document-oriented database. Distributed Version

Shard servers are  mongod instances. They store the actual data of the mongoDB cluster.
The are deployed as replicaset, each shard replicaset holds shards.

    module.exports =
      use:
        locale: module: 'masson/core/locale', local: true, auto: true, implicit: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        ssl: module: 'masson/core/ssl', local: true
        repo: module: 'ryba/mongodb/repo'
        config_servers: module: 'ryba/mongodb/configsrv'
        shard_servers: module: 'ryba/mongodb/shard'
      configure:
        'ryba/mongodb/shard/configure'
      commands:
        'check': ->
          options = @config.ryba.mongodb.shard
          @call 'ryba/mongodb/shard/check', options
        'install': ->
          options = @config.ryba.mongodb.shard
          @call 'ryba/mongodb/shard/install', options
          @call 'ryba/mongodb/shard/start', options
          @call 'ryba/mongodb/shard/wait', options
          @call 'ryba/mongodb/shard/replication', options
          @call 'ryba/mongodb/shard/check', options
        'start': ->
          options = @config.ryba.mongodb.shard
          @call 'ryba/mongodb/shard/start', options
        'stop': ->
          options = @config.ryba.mongodb.shard
          @call 'ryba/mongodb/shard/stop', options
        'status': ->
          options = @config.ryba.mongodb.shard
          @call 'ryba/mongodb/shard/status', options
