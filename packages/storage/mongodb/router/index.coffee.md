
# MongoDB Routing Server

Deploy the Query Router component of MongoDB. Query router care about Routing
client connection to the different members of the replica set. They are mongos
services

    module.exports =
      deps:
        locale: module: 'masson/core/locale', local: true, auto: true, implicit: true
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        repo: module: '@rybajs/storage/mongodb/repo'
        config_servers: '@rybajs/storage/mongodb/configsrv'
        shard_servers: '@rybajs/storage/mongodb/shard'
        router_servers: '@rybajs/storage/mongodb/router'
      configure:
        '@rybajs/storage/mongodb/router/configure'
      commands:
        'check':
          '@rybajs/storage/mongodb/router/check'
        'install': [
          '@rybajs/storage/mongodb/router/install'
          '@rybajs/storage/mongodb/router/start'
          '@rybajs/storage/mongodb/router/wait'
          '@rybajs/storage/mongodb/router/sharding'
          '@rybajs/storage/mongodb/router/check'
        ]
        'start':
          '@rybajs/storage/mongodb/router/start'
        'stop':
          '@rybajs/storage/mongodb/router/stop'
        'status':
          '@rybajs/storage/mongodb/router/status'
