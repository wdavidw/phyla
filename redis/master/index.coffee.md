
## Redis

[Redis][redis] is an open source (BSD licensed), in-memory data structure store,
used as a database, cache and message broker.

[redis]:https://redis.io/

    module.exports =
      use:
        yum: module: 'masson/core/yum', local: true
        iptables: module: 'masson/core/iptables', local: true
      configure: 'ryba/redis/master/configure'
      commands:
        'install': ->
          options = @config.ryba.redis.master
          @call 'ryba/redis/master/install', options
          @call 'ryba/redis/master/start', options
          @call 'ryba/redis/master/check', options
