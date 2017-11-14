
# Hadoop HDFS NameNode

NameNode’s primary responsibility is storing the HDFS namespace. This means things
like the directory tree, file permissions, and the mapping of files to block
IDs. It tracks where across the cluster the file data is kept on the DataNodes. It
does not store the data of these files itself. It’s important that this metadata
(and all changes to it) are safely persisted to stable storage for fault tolerance.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_jn: module: 'ryba/hadoop/hdfs_jn'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        ranger_admin: module: 'ryba/ranger/admin', single: true
        metrics: module: 'ryba/metrics', local: true
        log4j: module: 'ryba/log4j', local: true
      configure:
        'ryba/hadoop/hdfs_nn/configure'
      commands:
        'backup':
          'ryba/hadoop/hdfs_nn/backup'
        'check':
          'ryba/hadoop/hdfs_nn/check'
        'install': [
          'ryba/hadoop/hdfs_nn/install'
          'ryba/hadoop/hdfs_nn/start'
          'ryba/hadoop/hdfs_nn/layout'
          'ryba/hadoop/hdfs_nn/check'
        ]
        'start':
          'ryba/hadoop/hdfs_nn/start'
        'status':
          'ryba/hadoop/hdfs_nn/status'
        'stop':
          'ryba/hadoop/hdfs_nn/stop'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java
