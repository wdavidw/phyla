
# Schema Registry Stop

    module.exports = header: 'Schema Registry Stop', label_true: 'STOPPED', handler: ->
      @service.stop name: 'registry'
