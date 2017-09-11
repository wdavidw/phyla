
# DB Admin Wait

    module.exports =  header: 'HBase Master Wait', label_true: 'READY', handler: (options) ->

## TCP Port

      @connection.wait
        header: 'TCP'
        servers: options.tcp
