
# Oozie Server Check

    module.exports =  header: 'Oozie Server Check', handler: ({options}) ->

## Assert HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.wait.http
        retry: 3
        sleep: 3000
