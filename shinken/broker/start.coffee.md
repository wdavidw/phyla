
# Shinken Broker Start

    module.exports = header: 'Shinken Broker Start', handler: ->
      @service.start name: 'shinken-broker'
