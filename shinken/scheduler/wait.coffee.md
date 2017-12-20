
# Shinken Scheduler Wait

    module.exports = header: 'Shinken Scheduler Wait', handler: (options) ->
      @connection.wait options.wait.http
