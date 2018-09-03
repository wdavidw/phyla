
# HBase Start

Start the HBase Master server.

    module.exports = header: 'HBase Master Start', handler: ({options}) ->

## Wait

Wait for Kerberos, ZooKeeper and HDFS to be started.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @call 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.hdfs_conf_dir

## Service

You can also start the server manually with one of the following two commands:

```
service hbase-master start
systemctl start hbase-master
su -l hbase -c "/usr/hdp/current/hbase-master/bin/hbase-daemon.sh --config /etc/hbase-master/conf start master"
```

      @service.start
        # header: 'Service'
        name: 'hbase-master'
