
# Schema Registry Stop

    module.exports = header: 'Schema Registry Stop', handler: ->
      @service.stop name: 'registry'
