
# Shinken Reactionner Start

    module.exports = header: 'Shinken Reactionner Start', handler: (options) ->
      @service.start name: 'shinken-reactionner'
