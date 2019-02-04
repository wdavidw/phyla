
# Titan

Titan is a distributed graph database. It is an hadoop-friendly implementation of [TinkerPop]
[Blueprints]. Therefore it also use ThinkerPop REPL [Gremlin], and Front server [Rexster]

    module.exports =
      deps: {}
      configure:
        '@rybajs/metal/titan/configure'
      commands:
        'prepare':
          '@rybajs/metal/titan/prepare'
        'install': [
          '@rybajs/metal/hbase/client'
          '@rybajs/metal/titan/install'
          '@rybajs/metal/titan/check'
        ]
        'check':
          '@rybajs/metal/titan/check'

## Resources

[TinkerPop]: http://www.tinkerpop.com/
[Blueprints]: https://github.com/tinkerpop/blueprints/wiki
[Gremlin]: https://github.com/tinkerpop/gremlin/wiki
[Rexster]: https://github.com/tinkerpop/rexster/wiki
