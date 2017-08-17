
# Hadoop HDFS DataNode

A [DataNode](http://wiki.apache.org/hadoop/DataNode) manages the storage attached
to the node it run on. There are usually one DataNode per node in the cluster.
HDFS exposes a file system namespace and allows user data to be stored in files.
Internally, a file is split into one or more blocks and these blocks are stored 
in a set of DataNodes. The DataNodes also perform block creation, deletion, and 
replication upon instruction from the NameNode.

To provide a fast failover in a Higth Availabity (HA) enrironment, it is
necessary that the Standby node have up-to-date information regarding the
location of blocks in the cluster. In order to achieve this, the DataNodes are
configured with the location of both NameNodes, and send block location
information and heartbeats to both.

    module.exports =
      use:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        iptables: module: 'masson/core/iptables', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
      configure:
        'ryba/hadoop/hdfs_dn/configure'
      commands:
        'check': ->
          options = @config.ryba.hdfs.dn
          @call 'ryba/hadoop/hdfs_dn/check', options
        'install': ->
          options = @config.ryba.hdfs.dn
          @call 'ryba/hadoop/hdfs_dn/install', options
          @call 'ryba/hadoop/hdfs_dn/start', options
          @call 'ryba/hadoop/hdfs_dn/check', options
        'start': ->
          options = @config.ryba.hdfs.dn
          @call 'ryba/hadoop/hdfs_dn/start', options
        'status':
          'ryba/hadoop/hdfs_dn/status'
        'stop':
          'ryba/hadoop/hdfs_dn/stop'
