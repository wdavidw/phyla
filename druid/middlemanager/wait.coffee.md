
# Druid MiddleManager Wait

    module.exports = header: 'Druid MiddleManager Wait', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
