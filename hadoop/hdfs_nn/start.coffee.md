
# Hadoop HDFS NameNode Start

Start the NameNode service as well as its ZKFC daemon. In HA mode, all
JournalNodes shall be previously started.

    module.exports = header: 'HDFS NN Start', handler: (options) ->

## Wait

      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @call 'ryba/hadoop/hdfs_jn/wait', once: true, options.wait_hdfs_jn

## Service

You can also start the server manually with the following two commands:

```
system hadoop-hdfs-namenode start
systemctl start hadoop-hdfs-namenode
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop-hdfs-namenode/conf --script hdfs start namenode"
```

      @service.start
        name: 'hadoop-hdfs-namenode'
