
# Shinken Reactionner Wait

    module.exports = header: 'Shinken Reactionner Wait', handler: (options) ->
      @connection.wait options.wait.tcp
