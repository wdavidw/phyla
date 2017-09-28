
# Druid Coordinator Wait

    module.exports = header: 'Druid Coordinator Wait', label_true: 'STOPPED', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
