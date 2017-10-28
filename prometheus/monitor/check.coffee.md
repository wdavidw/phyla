
# Prometheus Montior Check

    module.exports = header: 'Prometheus Monitor Check', handler: (options) ->

## Check Port

      @connection.assert
        header: 'TCP'
        servers: options.wait.tcp
        retry: 3
        sleep: 3000
