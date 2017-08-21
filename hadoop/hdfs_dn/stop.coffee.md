
# Hadoop HDFS DataNode Stop

Stop the DataNode service. It is recommended to stop a DataNode before its
associated the NameNodes.

You can also stop the server manually with one of the following two commands:

```
systemctl stop hadoop-hdfs-datanode
/usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf stop datanode
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-datanode.pid".

    module.exports = header: 'HDFS DN Stop', label_true: 'STOPPED', handler: (options) ->

      @service.stop
        header: 'HDFS DN Stop'
        name: 'hadoop-hdfs-datanode'

## Stop Clean Logs

      @system.execute
        header: 'HDFS DN Clean Logs'
        if: options.clean_logs
        cmd: "rm #{options.log_dir}/*-datanode-*"
        code_skipped: 1
