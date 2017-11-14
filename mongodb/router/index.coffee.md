
# MongoDB Routing Server

Deploy the Query Router component of MongoDB. Query router care about Routing
client connection to the different members of the replica set. They are mongos
services

    module.exports =
      deps:
        locale: module: 'masson/core/locale', local: true, auto: true, implicit: true
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        repo: module: 'ryba/mongodb/repo'
        config_servers: 'ryba/mongodb/configsrv'
        shard_servers: 'ryba/mongodb/shard'
        router_servers: 'ryba/mongodb/router'
      configure:
        'ryba/mongodb/router/configure'
      commands:
        'check':
          'ryba/mongodb/router/check'
        'install': [
          'ryba/mongodb/router/install'
          'ryba/mongodb/router/start'
          'ryba/mongodb/router/wait'
          'ryba/mongodb/router/sharding'
          'ryba/mongodb/router/check'
        ]
        'start':
          'ryba/mongodb/router/start'
        'stop':
          'ryba/mongodb/router/stop'
        'status':
          'ryba/mongodb/router/status'
