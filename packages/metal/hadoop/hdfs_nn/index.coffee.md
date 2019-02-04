
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
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_jn: module: '@rybajs/metal/hadoop/hdfs_jn'
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn'
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        metrics: module: '@rybajs/metal/metrics', local: true
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/hadoop/hdfs_nn/configure'
      commands:
        'backup':
          '@rybajs/metal/hadoop/hdfs_nn/backup'
        'check':
          '@rybajs/metal/hadoop/hdfs_nn/check'
        'install': [
          '@rybajs/metal/hadoop/hdfs_nn/install'
          '@rybajs/metal/hadoop/hdfs_nn/start'
          '@rybajs/metal/hadoop/hdfs_nn/layout'
          '@rybajs/metal/hadoop/hdfs_nn/check'
        ]
        'start':
          '@rybajs/metal/hadoop/hdfs_nn/start'
        'status':
          '@rybajs/metal/hadoop/hdfs_nn/status'
        'stop':
          '@rybajs/metal/hadoop/hdfs_nn/stop'

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java
