
# Shinken Poller Status

    module.exports =  header: 'Shinken Poller Status', handler: (options) ->
      @service.status name: 'shinken-poller'
