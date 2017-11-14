
# HBase Thrift Server Stop

Stop the Rest server. You can also stop the server manually with one of
the following two commands:

```
service hbase-thrift start
su -l hbase -c "/usr/hdp/current/hbase-client/bin/hbase-daemon.sh --config /etc/hbase/conf stop rest"
```

## Service

    module.exports =  header: 'HBase Thrift Stop', handler: (options) ->

      @service.stop
        header: 'Service'
        name: 'hbase-thrift'

## Stop Clean Logs

      @call
        header: 'Clean Logs'
        if: options.clean_logs
      , ->
        @system.execute
          cmd: "rm #{options.log_dir}/*-thrift-*"
          code_skipped: 1
        @system.execute
          cmd: "rm #{options.log_dir}/gc.log-*"
          code_skipped: 1
