
# NiFi Check

    module.exports = header: 'NiFi Check', handler: ->
      {nifi} = @config.ryba
      protocol = if nifi.config.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'
      webui = nifi.config.properties["nifi.web.#{protocol}.port"]

## Wait

      @call once: true, 'ryba/nifi/wait'

## Check TCP

      @connection.assert
        header: 'Check WebUI port'
        host: "#{@config.host}"
        port: "#{webui}"
        retry: 3
        interval: 5000
      @system.execute
        header: 'Check Node port'
        if: nifi.config.properties['nifi.cluster.is.node'] is 'true'
        cmd: "echo > /dev/tcp/#{@config.host}/#{nifi.config.properties['nifi.cluster.node.protocol.port']}"
      @system.execute
        header: 'Check Manager port'
        if: nifi.config.properties['nifi.cluster.is.manager'] is 'true'
        cmd: "echo > /dev/tcp/#{@config.host}/#{nifi.config.properties['nifi.cluster.manager.protocol.port']}"
      @system.execute
        header: 'Check Multicast port'
        if: nifi.config.properties['nifi.cluster.protocol.use.multicast'] is 'true'
        cmd: "echo > /dev/tcp/#{@config.host}/#{nifi.config.properties['nifi.cluster.protocol.multicast.port']}"
      @system.execute
        header: 'Check Input Socket port'
        if: nifi.config.properties['nifi.remote.input.socket.port'] and nifi.config.properties['nifi.remote.input.socket.port'] isnt ''
        cmd: "echo > /dev/tcp/#{@config.host}/#{nifi.config.properties['nifi.remote.input.socket.port']}"

## Check Rest Api
Executes a series of job to test NiFi functionning
curl -H "Content-Type: application/json" --negotiate -k  -X POST -d '[#{JSON.stringify pic}]' -u: https://
      #
