
# Druid Overlord Wait

    module.exports = header: 'Druid Overlord Wait', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
