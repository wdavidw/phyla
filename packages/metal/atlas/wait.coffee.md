
# Atlas Metadata Server Wait

Wait for Atlas Metadata Server to start.

    module.exports = header: 'Atlas Wait', handler: (options) ->

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.wait_http
