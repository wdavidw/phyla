
# MongoDB Routing Server

Deploy the Query Router component of MongoDB. Query router care about Routing
client connection to the different members of the replica set. They are mongos
services

    module.exports =
      use:
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
        'check': ->
          options = @config.ryba.mongodb.router
          @call 'ryba/mongodb/router/check', options
        'install': ->
          options = @config.ryba.mongodb.router
          @call 'ryba/mongodb/router/install', options
          @call 'ryba/mongodb/router/start', options
          @call 'ryba/mongodb/router/wait', options
          @call 'ryba/mongodb/router/sharding', options
          @call 'ryba/mongodb/router/check', options
        'start': ->
          options = @config.ryba.mongodb.router
          @call 'ryba/mongodb/router/start', options
        'stop': ->
          options = @config.ryba.mongodb.router
          @call 'ryba/mongodb/router/stop', options
        'status': ->
          options = @config.ryba.mongodb.router
          @call 'ryba/mongodb/router/status', options
