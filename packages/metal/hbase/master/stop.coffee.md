
# HBase Master Stop

Stop the RegionServer server.

The file storing the PID is "/var/run/hbase/yarn/hbase-hbase-master.pid".

    module.exports = header: 'HBase Master Stop', handler: ({options}) ->


## Service

You can also stop the server manually with one of the following two commands:

```
service hbase-master stop
systemctl stop hbase-master
su -l hbase -c "/usr/hdp/current/hbase-master/bin/hbase-daemon.sh --config /etc/hbase/conf stop master"
```

      @service.stop
        header: 'Service'
        name: 'hbase-master'

## Clean Logs

Remove the "\*-nodemanager-\*" log files if the property "clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        if: -> options.clean_logs
        cmd: "rm #{options.log_dir}/*-master-*"
        code_skipped: 1

Remove the "gc.log-*" log files if the property "clean_logs" is activated.

      @system.execute
        header: 'Clean GC Logs'
        if: -> options.clean_logs
        cmd: "rm #{options.log_dir}/gc.log-*"
        code_skipped: 1
