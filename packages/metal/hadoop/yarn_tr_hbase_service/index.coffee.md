
# Yarn Timeline Reader System Hbase Service

The [Yarn Timeline Reader][tr] new component shipped with YARN 3.Its backend is an hbase DB.
It can be embedded (local), or distributed etc.
This module install hbase as a system service on the YARN cluster. It is configured to use
HDFS as the HBase storage.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hdp_assembly: module: '@rybajs/metal/hdp/assembly'
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', auto: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn', required: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm', required: true
        # yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm', required: true
        ranger_admin: module: '@rybajs/metal/ranger/admin'
      configure:
        '@rybajs/metal/hadoop/yarn_tr_hbase_service/configure'
      plugin: ({options}) ->
        @after
          action: ['service', 'start']
          name: 'hadoop-yarn-resourcemanager'
        , ->
          @call '@rybajs/metal/hadoop/yarn_tr_hbase_service/install_rm', options
        @before
          action: ['service', 'start']
          name: 'hadoop-yarn-nodemanager'
        , ->
          @call '@rybajs/metal/hadoop/yarn_tr_hbase_service/install_nm', options

[tr]: https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServiceV2.html