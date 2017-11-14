
## Redis

[Redis][redis] is an open source (BSD licensed), in-memory data structure store,
used as a database, cache and message broker.

[redis]:https://redis.io/

    module.exports =
      deps:
        yum: module: 'masson/core/yum', local: true
        iptables: module: 'masson/core/iptables', local: true
      configure:
        'ryba/redis/master/configure'
      commands:
        'install': [
          'ryba/redis/master/install'
          'ryba/redis/master/start'
          'ryba/redis/master/check'
        ]
