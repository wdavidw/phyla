
# Kafka Broker Check

    module.exports = header: 'Kafka Broker Check', handler: ({options}) ->

## Assert
      
      @connection.assert
        header: 'PLAINTEXT'
        if: !!options.wait['PLAINTEXT']
        servers: options.wait['PLAINTEXT']?.filter (server) -> server.host is options.fqdn
              
      @connection.assert
        header: 'SSL'
        if: !!options.wait['SSL']
        servers: options.wait['SSL']?.filter (server) -> server.host is options.fqdn
      
      @connection.assert
        header: 'SASL_PLAINTEXT'
        if: !!options.wait['SASL_PLAINTEXT']
        servers: options.wait['SASL_PLAINTEXT']?.filter (server) -> server.host is options.fqdn
              
      @connection.assert
        header: 'SASL_SSL'
        if: !!options.wait['SASL_SSL']
        servers: options.wait['SASL_SSL']?.filter (server) -> server.host is options.fqdn

## Check TCP

Make sure the broker is listening. The default port is "9092".

      # @call header: 'Check TCP', ->
      #   for protocol in kafka.broker.protocols
      #     @system.execute
      #       cmd: "echo > /dev/tcp/#{@config.host}/#{kafka.broker.ports[protocol]}"
