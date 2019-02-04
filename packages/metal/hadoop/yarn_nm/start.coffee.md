
# YARN NodeManager Start

    module.exports = header: 'YARN NM Start', handler: ({options}) ->

## Wait

Wait for Kerberos, ZooKeeper and HDFS to be started.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call '@rybajs/metal/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @call '@rybajs/metal/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.conf_dir

## Start Service

Start the Yarn NodeManager service. You can also start the server manually with the
following two commands:

```
service hadoop-yarn-nodemanager start
su -l yarn -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && /usr/hdp/current/hadoop-yarn-nodemanager/sbin/yarn-daemon.sh --config /etc/hadoop-yarn-nodemanager/conf start nodemanager"
```

      @service.start header: 'Service', name: 'hadoop-yarn-nodemanager'
