
# Schema Registry Check

    module.exports = header: 'Schema Registry Check', handler: ->
      {registry} = @config.ryba

## Check App Port

      for con, i in registry.config.server.applicationConnectors
        @system.execute
          header: "Check App WebUI #{i+1}"
          cmd: "curl -k #{con.type}://#{@config.host}:#{con.port}"

## Check Admin Port

      for con, i in registry.config.server.adminConnectors
        @system.execute
          header: "Check Admin WebUI #{i+1}"
          cmd: "curl -k #{con.type}://#{@config.host}:#{con.port}"
