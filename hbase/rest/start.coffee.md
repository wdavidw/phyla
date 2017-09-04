
# HBase Rest Gateway Start

Start the Rest server. You can also start the server manually with one of the
following two commands:

```
service hbase-rest start
su -l hbase -c "/usr/hdp/current/hbase-client/bin/hbase-daemon.sh --config /etc/hbase/conf start rest"
```

The file storing the PID is "/var/run/hbase/hbase-hbase-rest.pid".

    module.exports = header: 'HBase Rest Start', label_true: 'STARTED', handler: (options) ->

Wait for Kerberos, ZooKeeper, HDFS and Hbase Master to be started.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @call 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn
      @call 'ryba/hbase/master/wait', once: true, options.wait_hbase_master

Start the service.

      @service.start
        name: 'hbase-rest'
