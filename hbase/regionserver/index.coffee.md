
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
        zookeeper_server: module: 'ryba/zookeeper/server'
        test_user: module: 'ryba/commons/test_user', local: true, auto: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', required: true
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn', local: true
        hbase_master: module: 'ryba/hbase/master', required: true
        hbase_regionserver: module: 'ryba/hbase/regionserver'
        ranger_admin: module: 'ryba/ranger/admin'
        ganglia_collector: module: 'ryba/retired/ganglia/collector'
        log4j: module: 'ryba/log4j', local: true
      configure:
        'ryba/hbase/regionserver/configure'
      commands:
        'check':
          'ryba/hbase/regionserver/check'
        'install': [
          'ryba/hbase/regionserver/install'
          'ryba/hbase/regionserver/start'
          'ryba/hbase/regionserver/check'
        ]
        'start':
          'ryba/hbase/regionserver/start'
        'status':
          'ryba/hbase/regionserver/status'
        'stop':
          'ryba/hbase/regionserver/stop'
