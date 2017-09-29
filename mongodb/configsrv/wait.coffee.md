
## Wait

    module.exports = header: 'MongoDB Config Server Wait', label_true: 'READY', handler: (options) ->
      @connection.wait options.wait.tcp
