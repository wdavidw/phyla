
# Hue Check

For now the check is only checking port state, and will succeed every by waiting
the server to start...

    module.exports = header: 'Hue Docker Check', handler: (options) ->
    
      @connection.assert
        header: 'http'
        servers: options.wait.http.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000

  # TODO: Novembre 2015 check hue server by adding a user with the webservice.
