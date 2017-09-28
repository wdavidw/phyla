
# Druid Overlord Wait

    module.exports = header: 'Druid Overlord Wait', label_true: 'STOPPED', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
