
# JMX Exporter Knox Check

    module.exports = header: 'JMX Exporter Knox Check', handler: (options) ->

## Check Port

      @connection.assert
        header: 'TCP'
        servers: options.wait.jmx
        retry: 3
        sleep: 3000
