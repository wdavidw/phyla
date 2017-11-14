
# Spark History Server Start

Start the History server. You can also start the server manually with the
following command:

```
su -l spark -c '/usr/hdp/current/spark-historyserver/sbin/start-history-server.sh'
```

    module.exports = header: 'Spark History Server Start', handler: (options) ->
      @wait.execute
        cmd: mkcmd.hdfs options.hdfs_krb5_user, """
        hdfs dfs -stat \"%u:%g\" #{options.conf['spark.eventLog.dir']} | grep #{options.user.name}
        """
      @service.start
        name: 'spark-history-server'

# Dependencies

    mkcmd = require '../../lib/mkcmd'
