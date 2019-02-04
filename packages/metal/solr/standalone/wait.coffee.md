
# Shinken Arbiter Wait

    module.exports = header: 'Solr Standalone Wait', handler: ->
      @connection.wait
        servers: for ctx in @contexts '@rybajs/metal/solr/standalone'
          host: ctx.config.host
          port: ctx.config.ryba.solr.single.port
