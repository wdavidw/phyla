
## Redis

[Redis][redis] is an open source (BSD licensed), in-memory data structure store,
used as a database, cache and message broker.

[redis]:https://redis.io/


    module.exports =
      use:
        yum: module:'masson/core/yum', local: true
        iptables: module: 'masson/core/iptables', local: true
        redis_master: 'ryba/redis/master'
      configure: 'ryba/redis/slave/configure'
      commands:
        'install': ->
          options = @config.ryba.redis.slave
          @call 'ryba/redis/slave/install', options
          @call 'ryba/redis/slave/start', options
          @call 'ryba/redis/slave/check', options
