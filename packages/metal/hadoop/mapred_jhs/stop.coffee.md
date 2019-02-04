
# MapReduce JobHistoryServer Stop

Stop the MapReduce Job History Password. You can also stop the server manually
with one of the following two commands:

```
service hadoop-mapreduce-historyserver stop
systemctl stop hadoop-mapreduce-historyserver
su -l mapred -c "/usr/hdp/current/hadoop-mapreduce-historyserver/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop-mapreduce-historyserver/conf stop historyserver"
```

The file storing the PID is "/var/run/hadoop-mapreduce/mapred-mapred-historyserver.pid".

    module.exports = header: 'MapReduce JHS Stop', handler: ->
      @service.stop
        name: 'hadoop-mapreduce-historyserver'
