
# Druid MiddleManager Wait

    module.exports = header: 'Druid MiddleManager Wait', label_true: 'STOPPED', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
