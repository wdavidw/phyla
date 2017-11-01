
# HBase Master

[HMaster](http://hbase.apache.org/book.html#_master) is the implementation of the Master Server.
The Master server is responsible for monitoring all RegionServer instances in the cluster, and is the interface for all metadata changes.
In a distributed cluster, the Master typically runs on the NameNode.
J Mohamed Zahoor goes into some more detail on the Master Architecture in this blog posting, [HBase HMaster Architecture](http://blog.zahoor.in/2012/08/hbase-hmaster-architecture/)

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        zookeeper_server: module: 'ryba/zookeeper/server', required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, required: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', required: true
        # hdfs_dn: module: 'ryba/hadoop/hdfs_dn', required: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        ranger_admin: module: 'ryba/ranger/admin', single: true
        hbase_master: module: 'ryba/hbase/master'
        ganglia_collector: module: 'ryba/retired/ganglia/collector', single: true
        metrics: module: 'ryba/metrics', local: true
      configure:
        'ryba/hbase/master/configure'
        # 'ryba/ranger/plugins/hbase/configure'
      commands:
        'check': ->
          options = @config.ryba.hbase.master
          @call 'ryba/hbase/master/check', options
        'install': ->
          options = @config.ryba.hbase.master
          @call 'ryba/hbase/master/install', options
          @call 'ryba/hbase/master/layout', options
          @call 'ryba/hbase/master/start', options
          @call 'ryba/hbase/master/check', options
        'start': ->
          options = @config.ryba.hbase.master
          @call 'ryba/hbase/master/start', options
        'stop': ->
          options = @config.ryba.hbase.master
          @call 'ryba/hbase/master/stop', options
