
# Hadoop ZKFC

The [ZKFailoverController (ZKFC)](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html) is a new component which is a ZooKeeper client which also monitors and manages the state of the NameNode.
 Each of the machines which runs a NameNode also runs a ZKFC, and that ZKFC is responsible for Health monitoring, ZooKeeper session management, ZooKeeper-based election.


    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true # implicit: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true # implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', local: true, required: true # implicit: true
      configure:
        'ryba/hadoop/zkfc/configure'
      plugin: ->
        options = @config.ryba.zkfc
        @before
          type: ['service', 'start']
          name: 'hadoop-hdfs-namenode'
        , ->
          @call 'ryba/hadoop/zkfc/install', options
          @call 'ryba/hadoop/zkfc/start', options
      commands:
        'check': ->
          options = @config.ryba.zkfc
          @call 'ryba/hadoop/zkfc/check', options
        'install': ->
          options = @config.ryba.zkfc
          @call 'ryba/hadoop/zkfc/install', options
          @call 'ryba/hadoop/zkfc/start', options
          @call 'ryba/hadoop/zkfc/check', options
        'start': ->
          options = @config.ryba.zkfc
          @call 'ryba/hadoop/zkfc/start', options
        'stop': ->
          options = @config.ryba.zkfc
          @call 'ryba/hadoop/zkfc/stop', options
        'status':
          'ryba/hadoop/zkfc/status'
