
# Schema Registry Start

    module.exports = header: 'Schema Registry Start', label_true: 'STARTED', handler: ->
      @service.start name: 'registry'
