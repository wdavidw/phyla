
# DB Admin Wait

    module.exports =  header: 'DB admin Wait', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
