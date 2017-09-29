
# Shinken Receiver Wait

    module.exports = header: 'Shinken Receiver Wait', handler: ->
      @connection.wait
        servers: for ctx in @contexts 'ryba/shinken/receiver'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.receiver.config.port
