
# Shinken Arbiter Wait

    module.exports = header: 'Shinken Arbiter Wait', handler: ->
      @connection.wait options.wait.tcp
