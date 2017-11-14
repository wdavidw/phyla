
# HBase Master

[HMaster](http://hbase.apache.org/book.html#_master) is the implementation of the Master Server.
The Master server is responsible for monitoring all RegionServer instances in the cluster, and is the interface for all metadata changes.
In a distributed cluster, the Master typically runs on the NameNode.
J Mohamed Zahoor goes into some more detail on the Master Architecture in this blog posting, [HBase HMaster Architecture](http://blog.zahoor.in/2012/08/hbase-hmaster-architecture/)

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true
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
        log4j: module: 'ryba/log4j', local: true
      configure:
        'ryba/hbase/master/configure'
      commands:
        'check':
          'ryba/hbase/master/check'
        'install': [
          'ryba/hbase/master/install'
          'ryba/hbase/master/layout'
          'ryba/hbase/master/start'
          'ryba/hbase/master/check'
        ]
        'start':
          'ryba/hbase/master/start'
        'stop':
          'ryba/hbase/master/stop'
