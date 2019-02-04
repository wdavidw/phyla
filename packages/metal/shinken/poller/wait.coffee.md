
# Shinken Poller Wait

    module.exports = header: 'Shinken Poller Wait', handler: (options) ->
      @connection.wait options.wait.tcp