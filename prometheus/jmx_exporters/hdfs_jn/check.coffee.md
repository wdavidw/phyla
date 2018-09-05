
# JMX Exporter Journalnode Check

    module.exports = header: 'JMX Exporter Journalnode Check', handler: ({options}) ->

## Check Port

      @connection.assert
        header: 'TCP'
        servers: options.wait.jmx
        retry: 3
        sleep: 3000
