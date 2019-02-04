
# Shinken Receiver Status

    module.exports =  header: 'Shinken Receiver Status', handler: (options) ->
      @service.status name: 'shinken-receiver'
