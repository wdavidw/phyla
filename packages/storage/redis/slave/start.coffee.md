
# Redis Master Start

Simply start the Master service by running:

```bash
  service redis start
```

    module.exports = header: 'Redis Master Start', handler: (options) ->
      
      @call '@rybajs/storage/redis/master/wait'
      @service.start
        name: 'redis'
