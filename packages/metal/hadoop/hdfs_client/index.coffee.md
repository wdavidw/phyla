
# Hadoop HDFS Client

[Clients][hdfs_client] contact NameNode for file metadata or file modifications
and perform actual file I/O directly with the DataNodes.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true, recommended: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        # hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn'
        log4j: module: '@rybajs/metal/log4j'
      configure:
        '@rybajs/metal/hadoop/hdfs_client/configure'
      commands:
        'check':
          '@rybajs/metal/hadoop/hdfs_client/check'
        'install': [
          '@rybajs/metal/hadoop/hdfs_client/install'
          '@rybajs/metal/hadoop/hdfs_client/check'
        ]

[hdfs_client]: http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html
