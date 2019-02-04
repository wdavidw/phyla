
## YARN TR HBase Embedded Wait

Wait for master and region server to be up.

    module.exports = header: 'YARN TR HBase Embedded Wait', handler: ({options}) ->

## Master Port

      @connection.wait
        header: 'Master Port'
        servers: options.master_rpc

      @connection.wait
        header: 'Master Info Port'
        servers: options.master_http

## HTTP Port

      @connection.wait
        header: 'RS Port'
        servers: options.regionserver_rpc

      @connection.wait
        header: 'RS Info Port'
        servers: options.regionserver_http
