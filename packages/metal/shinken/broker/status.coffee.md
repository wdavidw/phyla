
# Shinken Broker Status

    module.exports =  header: 'Shinken Broker Status', handler: (options) ->
      @service.status name: 'shinken-broker'
