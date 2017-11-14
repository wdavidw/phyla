
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
        repo: module: 'ryba/mongodb/repo'
        config_servers: module: 'ryba/mongodb/configsrv'
        shard_servers: module: 'ryba/mongodb/shard'
      configure:
        'ryba/mongodb/shard/configure'
      commands:
        'check':
          'ryba/mongodb/shard/check'
        'install': [
          'ryba/mongodb/shard/install'
          'ryba/mongodb/shard/start'
          'ryba/mongodb/shard/wait'
          'ryba/mongodb/shard/replication'
          'ryba/mongodb/shard/check'
        ]
        'start':
          'ryba/mongodb/shard/start'
        'stop':
          'ryba/mongodb/shard/stop'
        'status':
          'ryba/mongodb/shard/status'
