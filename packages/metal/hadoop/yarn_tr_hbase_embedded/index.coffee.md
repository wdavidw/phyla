
# Yarn Timeline Reader Embedded Hbase Service

The [Yarn Timeline Reader][tr] new component shipped with YARN 3.Its backend is an hbase DB.
It can be embedded (local), or distributed etc.
This module install hbase on one node. Administrators can still use it with hdfs backend.

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
        yarn_tr_hbase_embedded: module: '@rybajs/metal/hadoop/yarn_tr_hbase_embedded'
        ranger_admin: module: '@rybajs/metal/ranger/admin'
      configure:
        '@rybajs/metal/hadoop/yarn_tr_hbase_embedded/configure'
      commands:
        'check':
          '@rybajs/metal/hadoop/yarn_tr_hbase_embedded/check'
        'install': [
          '@rybajs/metal/hadoop/yarn_tr_hbase_embedded/install'
          '@rybajs/metal/hadoop/yarn_tr_hbase_embedded/start'
          '@rybajs/metal/hadoop/yarn_tr_hbase_embedded/check'
        ]
        'start':
          '@rybajs/metal/hadoop/yarn_tr_hbase_embedded/start'
        # 'status':
        #   '@rybajs/metal/hadoop/yarn_tr_hbase_embedded/status'
        'stop':
          '@rybajs/metal/hadoop/yarn_tr_hbase_embedded/stop'

[tr]: https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServiceV2.html