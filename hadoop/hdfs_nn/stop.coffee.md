
# Hadoop HDFS NameNode Stop


    module.exports = header: 'HDFS NN Stop', handler: (options) ->

## Stop Service

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
system hadoop-hdfs-namenode stop
systemctl stop hadoop-hdfs-namenode
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop-hdfs-namenode/conf --script hdfs stop namenode"
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-namenode.pid".

      @service.stop
        header: 'HDFS NN Stop'
        name: 'hadoop-hdfs-namenode'

## Stop Clean Logs

Remove the "\*-namenode-\*" log files if the property "ryba.clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        cmd: "rm #{options.log_dir}/*-namenode-*"
        code_skipped: 1
        if: options.clean_logs
