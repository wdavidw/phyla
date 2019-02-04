
# Druid Broker Wait

    module.exports = header: 'Druid Broker Wait', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
