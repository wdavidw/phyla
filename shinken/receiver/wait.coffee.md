
# Shinken Receiver Wait

    module.exports = header: 'Shinken Receiver Wait', handler: ->
      @connection.wait options.wait.tcp
