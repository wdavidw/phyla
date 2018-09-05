
# JMX Exporter HBase Master Check

    module.exports = header: 'JMX Exporter HBase Master Check', handler: ({options}) ->

## Check Port

      @connection.assert
        header: 'TCP'
        servers: options.wait.jmx
        retry: 3
        sleep: 3000
