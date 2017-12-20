
# Shinken Broker Wait

    module.exports = header: 'Shinken Broker Wait', handler: (options) ->
      @connection.wait options.wait.tcp
