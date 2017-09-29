
# DB Admin Wait

    module.exports =  header: 'HBase Master Wait', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
