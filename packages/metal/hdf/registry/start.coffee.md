
# Schema Registry Start

    module.exports = header: 'Schema Registry Start', handler: ->
      @service.start name: 'registry'
