
# Hadoop ZKFC

The [ZKFailoverController (ZKFC)](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html) is a new component which is a ZooKeeper client which also monitors and manages the state of the NameNode.
 Each of the machines which runs a NameNode also runs a ZKFC, and that ZKFC is responsible for Health monitoring, ZooKeeper session management, ZooKeeper-based election.


    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hdfs_nn_local: module: '@rybajs/metal/hadoop/hdfs_nn', local: true, required: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
      configure:
        '@rybajs/metal/hadoop/zkfc/configure'
      plugin: ({options}) ->
        @after
          action: ['service', 'start']
          name: 'hadoop-hdfs-namenode'
        , ->
          @call '@rybajs/metal/hadoop/zkfc/install', options
          @call '@rybajs/metal/hadoop/zkfc/start', options
      commands:
        'check':
          '@rybajs/metal/hadoop/zkfc/check'
        'install': [
          '@rybajs/metal/hadoop/zkfc/install'
          '@rybajs/metal/hadoop/zkfc/start'
          '@rybajs/metal/hadoop/zkfc/check'
        ]
        'start':
          '@rybajs/metal/hadoop/zkfc/start'
        'stop':
          '@rybajs/metal/hadoop/zkfc/stop'
        'status':
          '@rybajs/metal/hadoop/zkfc/status'
