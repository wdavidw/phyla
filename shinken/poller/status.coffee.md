
# Shinken Poller Status

    module.exports =  header: 'Shinken Poller Status', handler: ->
      @service.status name: 'shinken-poller'
