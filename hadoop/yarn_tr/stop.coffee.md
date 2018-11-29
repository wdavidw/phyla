
# Hadoop YARN Timeline Server Stop

Stop the HDFS Namenode service. You can also stop the server manually with one of
the following two commands:

```
service hadoop-yarn-timelineserver stop
su -l yarn -c "/usr/hdp/current/hadoop-yarn-timelineserver/sbin/yarn-daemon.sh --config /etc/hadoop/conf stop timelineserver"
```

The file storing the PID is "/var/run/hadoop-yarn/yarn/yarn-yarn-timelineserver.pid".

    module.exports = header: 'YARN TR Stop', handler: ->
      @service.stop
        header: 'Stop service'
        name: 'hadoop-yarn-timelinereader'
