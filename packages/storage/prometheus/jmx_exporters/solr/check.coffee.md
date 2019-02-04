
# JMX Exporter Solr Check

    module.exports = header: 'JMX Exporter Solr Check', handler: (options) ->

## Check Port

      @connection.assert
        header: 'TCP'
        servers: options.wait.jmx
        retry: 3
        sleep: 3000
