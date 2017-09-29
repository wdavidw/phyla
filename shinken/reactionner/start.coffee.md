
# Shinken Reactionner Start

    module.exports = header: 'Shinken Reactionner Start', handler: ->
      @service.start name: 'shinken-reactionner'
