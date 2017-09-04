
# HBase Master Wait

    module.exports =  header: 'HBase Master Wait', label_true: 'READY', handler: (options) ->

## RPC Port

      @connection.wait
        header: 'RPC'
        servers: options.rpc

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.http
