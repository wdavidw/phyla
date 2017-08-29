
# Hadoop HDFS NameNode

NameNode’s primary responsibility is storing the HDFS namespace. This means things
like the directory tree, file permissions, and the mapping of files to block
IDs. It tracks where across the cluster the file data is kept on the DataNodes. It
does not store the data of these files itself. It’s important that this metadata
(and all changes to it) are safely persisted to stable storage for fault tolerance.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_jn: module: 'ryba/hadoop/hdfs_jn'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        ranger_admin: module: 'ryba/ranger/admin', single: true
      configure:
        'ryba/hadoop/hdfs_nn/configure'
        # 'ryba/ranger/plugins/hdfs/configure'
      commands:
        'backup':
          'ryba/hadoop/hdfs_nn/backup'
        'check': ->
          options = @config.ryba.hdfs.nn
          @call 'ryba/hadoop/hdfs_nn/check', options
        'install': ->
          options = @config.ryba.hdfs.nn
          @call 'ryba/hadoop/hdfs_nn/install', options
          @call 'ryba/hadoop/hdfs_nn/start', options
          # @call 'ryba/hadoop/zkfc/install', options
          # @call 'ryba/hadoop/zkfc/start', options
          @call 'ryba/hadoop/hdfs_nn/layout', options
          @call 'ryba/hadoop/hdfs_nn/check', options
          # @call 'ryba/ranger/plugins/hdfs/setup', options
        'start': ->
          options = @config.ryba.hdfs.nn
          @call 'ryba/hadoop/hdfs_nn/start', options
        'status':
          'ryba/hadoop/hdfs_nn/status'
        'stop': ->
          options = @config.ryba.hdfs.nn
          @call 'ryba/hadoop/hdfs_nn/stop', options

[keys]: https://github.com/apache/hadoop-common/blob/trunk/hadoop-hdfs-project/hadoop-hdfs/src/main/java/org/apache/hadoop/hdfs/DFSConfigKeys.java
