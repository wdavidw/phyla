
# HBase Rest server Wait

    module.exports = header: 'HBase Rest Wait', handler: ({options}) ->

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.http

## HTTP Info Port

      @connection.wait
        header: 'HTTP Info'
        servers: options.http_info
