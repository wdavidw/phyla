
# HBase RegionServer

[HRegionServer](http://hbase.apache.org/book.html#regionserver.arch) is the
RegionServer implementation.
It is responsible for serving and managing regions. 
In a distributed cluster, a RegionServer runs on a DataNode.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', required: true
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn', local: true, required: true
        hbase_master: module: 'ryba/hbase/master', required: true
        hbase_regionserver: module: 'ryba/hbase/regionserver'
        ranger_admin: module: 'ryba/ranger/admin'
        ganglia_collector: module: 'ryba/ganglia/collector'
      configure:
        'ryba/hbase/regionserver/configure'
        # 'ryba/ranger/plugins/hbase/configure'
      commands:
        'check': ->
          options = @config.ryba.hbase.regionserver
          @call 'ryba/hbase/regionserver/check', options
        'install': ->
          options = @config.ryba.hbase.regionserver
          @call 'ryba/hbase/regionserver/install', options
          @call 'ryba/hbase/regionserver/start', options
          @call 'ryba/hbase/regionserver/check', options
        'start': ->
          options = @config.ryba.hbase.regionserver
          @call 'ryba/hbase/regionserver/start', options
        'status':
          'ryba/hbase/regionserver/status'
        'stop': ->
          options = @config.ryba.hbase.regionserver
          @call 'ryba/hbase/regionserver/stop', options
