
# Spark SQL Thrift server Stop

Stops the Spark SQL Thrift server. You can also start the server manually with the
following command:

```
service spark-thrift-server start
```

    module.exports = header: 'Spark SQL Thrift Server Stop', handler: ({options}) ->
      @service.stop
        name: 'spark-thrift-server'

## Clean Logs

      @call header: 'Clean Logs', ->
        return unless options.clean_logs
        @system.execute
          cmd: "rm #{options.log_dir}/*"
          code_skipped: 1
