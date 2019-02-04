
# HBase RegionServer Stop

Stop the RegionServer server.

The file storing the PID is "/var/run/hbase/yarn/hbase-hbase-regionserver.pid".

    module.exports = header: 'HBase RegionServer Stop', handler: ({options}) ->

## Service

You can also stop the server manually with one of the following two commands:

```
service hbase-regionserver stop
systemctl stop hbase-regionserver
su -l hbase -c "/usr/hdp/current/hbase-regionserver/bin/hbase-daemon.sh --config /etc/hbase-regionserver/conf stop regionserver"
```

      @service.stop
        header: 'Service'
        name: 'hbase-regionserver'

## Clean Logs

Remove the "\*-nodemanager-\*" log files if the property "clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        if: options.clean_logs
        cmd: "rm #{options.log_dir}/*-regionserver-*"
        code_skipped: 1

Remove the "gc.log-*" log files if the property "clean_logs" is activated.

      @system.execute
        header: 'Clean GC Logs'
        if: options.clean_logs
        cmd: "rm #{options.log_dir}/gc.log-*"
        code_skipped: 1
