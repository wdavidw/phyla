
## Redis

[Redis][redis] is an open source (BSD licensed), in-memory data structure store,
used as a database, cache and message broker.

[redis]:https://redis.io/


    module.exports =
      use:
        yum: module:'masson/core/yum', local: true
        iptables: module: 'masson/core/iptables', local: true
        redis_master: '@rybajs/storage/redis/master'
      configure: '@rybajs/storage/redis/slave/configure'
      commands:
        'install': ->
          options = @config.ryba.redis.slave
          @call '@rybajs/storage/redis/slave/install', options
          @call '@rybajs/storage/redis/slave/start', options
          @call '@rybajs/storage/redis/slave/check', options
