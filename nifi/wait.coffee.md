
# NiFi Wait

    module.exports = header: 'NiFi Wait', handler: (options) ->

## Web UI Port

      @connection.wait
        header: 'Web UI'
        servers: options.webui
