
# Shinken Broker Start

    module.exports = header: 'Shinken Broker Start', handler: (options) ->
      @service.start name: 'shinken-broker'
