
# Yarn Timeline Reader Embedded Hbase Service

The [Yarn Timeline Reader][tr] new component shipped with YARN 3.Its backend is an hbase DB.
It can be embedded (local), or distributed etc.
This module install hbase on one node. Administrators can still use it with hdfs backend.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hdp_assembly: module: 'ryba/hdp/assembly'
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', auto: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', required: true
        yarn_tr_hbase_embedded: module: 'ryba/hadoop/yarn_tr_hbase_embedded'
        ranger_admin: module: 'ryba/ranger/admin'
      configure:
        'ryba/hadoop/yarn_tr_hbase_embedded/configure'
      commands:
        'check':
          'ryba/hadoop/yarn_tr_hbase_embedded/check'
        'install': [
          'ryba/hadoop/yarn_tr_hbase_embedded/install'
          'ryba/hadoop/yarn_tr_hbase_embedded/start'
          'ryba/hadoop/yarn_tr_hbase_embedded/check'
        ]
        'start':
          'ryba/hadoop/yarn_tr_hbase_embedded/start'
        # 'status':
        #   'ryba/hadoop/yarn_tr_hbase_embedded/status'
        'stop':
          'ryba/hadoop/yarn_tr_hbase_embedded/stop'

[tr]: https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServiceV2.html