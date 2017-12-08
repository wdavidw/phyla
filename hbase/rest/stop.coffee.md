
# HBase Rest Gateway Stop

Stop the Rest server. You can also stop the server manually with one of
the following two commands:

```
service hbase-rest start
su -l hbase -c "/usr/hdp/current/hbase-client/bin/hbase-daemon.sh --config /etc/hbase/conf stop rest"
```

## Service

    module.exports =  header: 'HBase Rest Stop', handler: (options) ->
      {hbase, clean_logs} = @config.ryba
      @service.stop
        header: 'Service'
        name: 'hbase-rest'

## Stop Clean Logs

      @call
        header: 'Clean Logs'
        if: -> @config.ryba.clean_logs
      , ->
        @system.execute
          cmd: "rm #{hbase.log_dir}/*-rest-*"
          code_skipped: 1
        @system.execute
          cmd: "rm #{hbase.log_dir}/gc.log-*"
          code_skipped: 1
