
# Hadoop HDFS DataNode Stop

Stop the DataNode service. It is recommended to stop a DataNode before its
associated the NameNodes.

    module.exports = header: 'HDFS DN Stop', label_true: 'STOPPED', handler: (options) ->

## Service

You can also stop the server manually with one of the following two commands:

```
system hadoop-hdfs-datanode stop
systemctl stop hadoop-hdfs-datanode
/usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop-hdfs-datanode/conf stop datanode
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-datanode.pid".

      @service.stop
        header: 'HDFS DN Stop'
        name: 'hadoop-hdfs-datanode'

## Stop Clean Logs

      @system.execute
        header: 'HDFS DN Clean Logs'
        if: options.clean_logs
        cmd: "rm #{options.log_dir}/*-datanode-*"
        code_skipped: 1
