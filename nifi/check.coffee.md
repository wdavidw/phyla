
# NiFi Check

    module.exports = header: 'NiFi Check', handler: (options) ->
      protocol = if options.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'
      webui = options.properties["nifi.web.#{protocol}.port"]

## Wait

      @call once: true, 'ryba/nifi/wait', options.wait

## Check TCP

      @connection.assert
        header: 'Check WebUI port'
        host: "#{options.fqdn}"
        port: "#{webui}"
        retry: 3
        interval: 5000
      @system.execute
        header: 'Check Node port'
        if: options.properties['nifi.cluster.is.node'] is 'true'
        cmd: "echo > /dev/tcp/#{options.fqdn}/#{options.properties['nifi.cluster.node.protocol.port']}"
      @system.execute
        header: 'Check Manager port'
        if: options.properties['nifi.cluster.is.manager'] is 'true'
        cmd: "echo > /dev/tcp/#{options.fqdn}/#{options.properties['nifi.cluster.manager.protocol.port']}"
      @system.execute
        header: 'Check Multicast port'
        if: options.properties['nifi.cluster.protocol.use.multicast'] is 'true'
        cmd: "echo > /dev/tcp/#{options.fqdn}/#{options.properties['nifi.cluster.protocol.multicast.port']}"
      @system.execute
        header: 'Check Input Socket port'
        if: options.properties['nifi.remote.input.socket.port'] and options.properties['nifi.remote.input.socket.port'] isnt ''
        cmd: "echo > /dev/tcp/#{options.fqdn}/#{options.properties['nifi.remote.input.socket.port']}"

## Check Rest Api
Executes a series of job to test NiFi functionning
curl -H "Content-Type: application/json" --negotiate -k  -X POST -d '[#{JSON.stringify pic}]' -u: https://
      #
