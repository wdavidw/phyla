
# Shinken Broker Status

    module.exports =  header: 'Shinken Broker Status', handler: ->
      @service.status name: 'shinken-broker'
