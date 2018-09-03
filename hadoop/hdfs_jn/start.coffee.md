
# Hadoop HDFS JournalNode Start

Start the JournalNode service. It is recommended to start a JournalNode before the
NameNodes. The "ryba/hadoop/hdfs_nn" module will wait for all the JournalNodes
to be started on the active NameNode before it check if it must be formated.

You can also start the server manually with the following two commands:

```
service hadoop-hdfs-journalnode start
su -l hdfs -c "/usr/hdp/current/hadoop-hdfs-journalnode/../hadoop/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start journalnode"
```

    module.exports = header: 'HDFS JN Start', handler: ({options}) ->

## Wait

Wait for the Kerberos server and Zookeeper server.

      @call once: true, 'masson/core/krb5_client/wait', options.wait_krb5_client
      @call once: true, 'ryba/zookeeper/server/wait', options.wait_zookeeper_server

## Service

      @service.start name: 'hadoop-hdfs-journalnode'
