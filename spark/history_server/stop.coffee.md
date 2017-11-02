
# Spark History Server Stop

Stop the History server. You can also stop the server manually with the
following command:

```
su -l spark -c '/usr/hdp/current/spark-historyserver/sbin/stop-history-server.sh'
```

    module.exports = header: 'Spark History Server Stop', handler: ->
      @service.stop
        name: 'spark-history-server'
