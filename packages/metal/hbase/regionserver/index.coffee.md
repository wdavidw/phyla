
# HBase RegionServer

[HRegionServer](http://hbase.apache.org/book.html#regionserver.arch) is the
RegionServer implementation.
It is responsible for serving and managing regions. 
In a distributed cluster, a RegionServer runs on a DataNode.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn', required: true
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn', local: true
        hbase_master: module: '@rybajs/metal/hbase/master', required: true
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver'
        ranger_admin: module: '@rybajs/metal/ranger/admin'
        ganglia_collector: module: '@rybajs/metal/retired/ganglia/collector'
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/hbase/regionserver/configure'
      commands:
        'check':
          '@rybajs/metal/hbase/regionserver/check'
        'install': [
          '@rybajs/metal/hbase/regionserver/install'
          '@rybajs/metal/hbase/regionserver/start'
          '@rybajs/metal/hbase/regionserver/check'
        ]
        'start':
          '@rybajs/metal/hbase/regionserver/start'
        'status':
          '@rybajs/metal/hbase/regionserver/status'
        'stop':
          '@rybajs/metal/hbase/regionserver/stop'
