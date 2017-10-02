
# MongoDB Shard Check

    module.exports = header: 'MongoDB Shard Check', label_true: 'CHECKED', handler: (options) ->

## Check 

      @connection.assert
        header: 'TCP'
        servers: options.wait_local
        retry: 3
        sleep: 3000
