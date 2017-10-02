
# MongoDB Routing Server Check

    module.exports = header: 'MongoDB Router Server Check', handler: (options) ->
      
## Check

      @connection.assert
        header: 'TCP'
        servers: options.wait_local
        retry: 3
        sleep: 3000
