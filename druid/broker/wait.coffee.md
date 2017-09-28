
# Druid Broker Wait

    module.exports = header: 'Druid Broker Wait', label_true: 'STOPPED', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
