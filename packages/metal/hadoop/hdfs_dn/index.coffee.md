
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
      deps:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        iptables: module: 'masson/core/iptables', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn'
        metrics: module: '@rybajs/metal/metrics', local: true
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/hadoop/hdfs_dn/configure'
      commands:
        'check':
          '@rybajs/metal/hadoop/hdfs_dn/check'
        'install': [
          '@rybajs/metal/hadoop/hdfs_dn/install'
          '@rybajs/metal/hadoop/hdfs_dn/start'
          '@rybajs/metal/hadoop/hdfs_dn/check'
        ]
        'start':
          '@rybajs/metal/hadoop/hdfs_dn/start'
        'status':
          '@rybajs/metal/hadoop/hdfs_dn/status'
        'stop':
          '@rybajs/metal/hadoop/hdfs_dn/stop'
