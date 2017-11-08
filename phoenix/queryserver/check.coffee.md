
# Phoenix QueryServer Check

    module.exports = header: 'Phoenix QueryServer Check', handler: (options) ->
      http =
        host: options.host
        port: options.queryserver.site['phoenix.queryserver.http.port']

## Check TCP

      @connection.wait servers: http
