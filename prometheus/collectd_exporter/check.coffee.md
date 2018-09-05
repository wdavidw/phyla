
# Collectd Exporter Check

    module.exports = header: 'Collectd Exporter Check', handler: ({options}) ->

## Check Port

      @connection.assert
        header: 'TCP'
        servers: options.wait.jmx
        retry: 3
        sleep: 3000
