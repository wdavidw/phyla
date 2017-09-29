
# Shinken Receiver Start

    module.exports = header: 'Shinken Receiver Start', handler: ->
      @service.start name: 'shinken-receiver'
