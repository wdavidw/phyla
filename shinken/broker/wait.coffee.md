
# Shinken Broker Wait

    module.exports = header: 'Shinken Broker Wait', handler: ->
      @connection.wait
        servers: for ctx in @contexts 'ryba/shinken/broker'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.broker.config.port
