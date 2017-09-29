
# Shinken Receiver Status

    module.exports =  header: 'Shinken Receiver Status', handler: ->
      @service.status name: 'shinken-receiver'
