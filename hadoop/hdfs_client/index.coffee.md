
# Hadoop HDFS Client

[Clients][hdfs_client] contact NameNode for file metadata or file modifications
and perform actual file I/O directly with the DataNodes.

    module.exports =
      use:
        java: module: 'masson/commons/java', local: true, recommended: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
      configure:
        'ryba/hadoop/hdfs_client/configure'
      commands:
        'check':
          'ryba/hadoop/hdfs_client/check'
        'install': ->
          options = @config.ryba.hdfs_client
          @call 'ryba/hadoop/hdfs_client/install', options
          @call 'ryba/hadoop/hdfs_client/check', options

[hdfs_client]: http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html
