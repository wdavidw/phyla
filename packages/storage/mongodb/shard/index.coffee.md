
# MongoDB Shard (Distributed)

MongoDB is a document-oriented database. Distributed Version

Shard servers are  mongod instances. They store the actual data of the mongoDB cluster.
The are deployed as replicaset, each shard replicaset holds shards.

    module.exports =
      deps:
        locale: module: 'masson/core/locale', local: true, auto: true, implicit: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        ssl: module: 'masson/core/ssl', local: true
        repo: module: '@rybajs/storage/mongodb/repo'
        config_servers: module: '@rybajs/storage/mongodb/configsrv'
        shard_servers: module: '@rybajs/storage/mongodb/shard'
      configure:
        '@rybajs/storage/mongodb/shard/configure'
      commands:
        'check':
          '@rybajs/storage/mongodb/shard/check'
        'install': [
          '@rybajs/storage/mongodb/shard/install'
          '@rybajs/storage/mongodb/shard/start'
          '@rybajs/storage/mongodb/shard/wait'
          '@rybajs/storage/mongodb/shard/replication'
          '@rybajs/storage/mongodb/shard/check'
        ]
        'start':
          '@rybajs/storage/mongodb/shard/start'
        'stop':
          '@rybajs/storage/mongodb/shard/stop'
        'status':
          '@rybajs/storage/mongodb/shard/status'
