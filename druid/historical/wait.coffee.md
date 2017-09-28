
# Druid Historical Wait

    module.exports = header: 'Druid Historical Wait', label_true: 'STOPPED', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
