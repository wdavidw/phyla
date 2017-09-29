
## Wait

    module.exports = header: 'MongoDB Shard Server Wait', handler: (options) ->
      @connection.wait options.tcp
