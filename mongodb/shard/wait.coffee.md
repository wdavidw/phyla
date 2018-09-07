
## Wait

    module.exports = header: 'MongoDB Shard Server Wait', label_true: 'READY', handler: ({options}) ->
      @connection.wait options.tcp
