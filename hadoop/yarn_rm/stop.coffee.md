
# Hadoop YARN ResourceManager Stop

    module.exports = header: 'YARN RM Stop', label_true: 'STOPPED', handler: (options) ->

## Stop

Stop the Hive HCatalog server. You can also stop the server manually with one of
the following two commands:

```
service hadoop-yarn-resourcemanager stop
su -l yarn -c "/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop resourcemanager"
```

The file storing the PID is "/var/run/hadoop-yarn/yarn/yarn-yarn-resourcemanager.pid".

      @service.stop
        header: 'Stop service'
        label_true: 'STOPPED'
        name: 'hadoop-yarn-resourcemanager'

## Stop Clean Logs

Remove the "\*-resourcemanager-\*" log files if the property "ryba.clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        label_true: 'CLEANED'
        if: options.clean_logs
        cmd: 'rm #{options.log_dir}/*/*-resourcemanager-*'
        code_skipped: 1
