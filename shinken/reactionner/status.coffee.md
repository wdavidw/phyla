
# Shinken Reactionner Status

    module.exports =  header: 'Shinken Reactionner Status', handler: ->
      @service.status name: 'shinken-reactionner'
