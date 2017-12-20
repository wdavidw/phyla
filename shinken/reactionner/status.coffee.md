
# Shinken Reactionner Status

    module.exports =  header: 'Shinken Reactionner Status', handler: (options) ->
      @service.status name: 'shinken-reactionner'
