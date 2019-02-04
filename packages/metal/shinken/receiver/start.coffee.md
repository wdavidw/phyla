
# Shinken Receiver Start

    module.exports = header: 'Shinken Receiver Start', handler: (options) ->
      @service.start name: 'shinken-receiver'
