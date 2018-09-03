
# Hadoop HDFS SecondaryNameNode Stop

    module.exports = header: 'HDFS SNN Stop', handler: ({options}) ->

## Stop Service

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-secondarynamenode stop
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop secondarynamenode"
```

      @service.stop
        header: 'Stop service'
        name: 'hadoop-hdfs-secondarynamenode'

## Stop Clean Logs

Remove the "\*-namenode-\*" log files if the property "ryba.clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        cmd: 'rm /var/log/hadoop-hdfs/*/*-secondarynamenode-*'
        code_skipped: 1
        if: options.clean_logs
