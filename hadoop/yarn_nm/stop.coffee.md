
# YARN NodeManager Stop

    module.exports = header: 'YARN NM Stop', label_true: 'STOPPED', handler: ->

## Stop Service

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-yarn-nodemanager stop
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec && /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop nodemanager"
```

The file storing the PID is "/var/run/hadoop-yarn/yarn/yarn-yarn-nodemanager.pid".

      @service.stop
        header: 'YARN NM Stop'
        label_true: 'STOPPED'
        name: 'hadoop-yarn-nodemanager'

## Stop Clean Logs

Remove the "\*-nodemanager-\*" log files if the property "ryba.clean_logs" is
activated.

      @system.execute
        header: 'YARN NM Clean Logs'
        if: options.clean_logs
        cmd: 'rm #{options.log_dir}/*/*-nodemanager-*'
        code_skipped: 1
