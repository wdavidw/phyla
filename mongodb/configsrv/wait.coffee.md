
## Wait

    module.exports = header: 'MongoDB Config Server Wait', handler: (options) ->
      @connection.wait options.tcp
