
# Phoenix QueryServer Check

    module.exports = header: 'Phoenix QueryServer Check', handler: ({options}) ->
      http =
        host: options.host
        port: options.phoenix_site['phoenix.queryserver.http.port']

## Check TCP

      @connection.wait servers: http
