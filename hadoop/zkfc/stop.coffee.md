
# Hadoop ZKFC Stop

    module.exports = header: 'HDFS ZKFC Stop', handler: (options) ->

## Stop

Stop the ZKFC deamon. You can also stop the server manually with one of
the following two commands:

```
service hadoop-hdfs-zkfc stop
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs stop zkfc"
```

The file storing the PID is "/var/run/hadoop-hdfs/hadoop-hdfs-zkfc.pid".

      @service.stop
        header: 'Daemon'
        name: 'hadoop-hdfs-zkfc'

      @system.execute
        header: 'Clean Logs'
        if: options.clean_logs
        cmd: 'rm /var/log/hadoop-hdfs/*-zkfc-*'
        code_skipped: 1
