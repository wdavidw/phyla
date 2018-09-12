
# Hadoop ZKFC

The [ZKFailoverController (ZKFC)](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html) is a new component which is a ZooKeeper client which also monitors and manages the state of the NameNode.
 Each of the machines which runs a NameNode also runs a ZKFC, and that ZKFC is responsible for Health monitoring, ZooKeeper session management, ZooKeeper-based election.


    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hdfs_nn_local: module: 'ryba/hadoop/hdfs_nn', local: true, required: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
      configure:
        'ryba/hadoop/zkfc/configure'
      plugin: ({options}) ->
        @after
          action: ['service', 'start']
          name: 'hadoop-hdfs-namenode'
        , ->
          @call 'ryba/hadoop/zkfc/install', options
          @call 'ryba/hadoop/zkfc/start', options
      commands:
        'check':
          'ryba/hadoop/zkfc/check'
        'install': [
          'ryba/hadoop/zkfc/install'
          'ryba/hadoop/zkfc/start'
          'ryba/hadoop/zkfc/check'
        ]
        'start':
          'ryba/hadoop/zkfc/start'
        'stop':
          'ryba/hadoop/zkfc/stop'
        'status':
          'ryba/hadoop/zkfc/status'
