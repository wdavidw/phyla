
# Shinken Arbiter Wait

    module.exports = header: 'Shinken Arbiter Wait', handler: ->
      @connection.wait
        servers: for ctx in @contexts 'ryba/shinken/arbiter'
          host: ctx.config.host
          port: ctx.config.ryba.shinken.arbiter.config.port
