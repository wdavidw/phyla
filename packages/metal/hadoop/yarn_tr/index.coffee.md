
# Yarn Timeline Reader

The [Yarn Timeline Reader][tr] new component shipped with YARN 3. Its role is to answer queries concerning
Jobs metadata.
The TimeLineService v1 has become v2 and is now divided into two parts in order to be scalable.
 - The Timeline Reader which can be high available.
 - The Timeline Writer which is embeeded in Yarn ResourceManagers and Yarn NodeManagers.

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
        yarn_tr: module: '@rybajs/metal/hadoop/yarn_tr'
        yarn_tr_hbase_embedded: module: '@rybajs/metal/hadoop/yarn_tr_hbase_embedded'
        yarn_tr_hbase_service: module: '@rybajs/metal/hadoop/yarn_tr_hbase_service'
        zookeeper: module: '@rybajs/metal/zookeeper/server'
      configure:
        '@rybajs/metal/hadoop/yarn_tr/configure'
      commands:
        'check':
          '@rybajs/metal/hadoop/yarn_tr/check'
        'install': [
          '@rybajs/metal/hadoop/yarn_tr/install'
          '@rybajs/metal/hadoop/yarn_tr/setup'
          '@rybajs/metal/hadoop/yarn_tr/start'
          '@rybajs/metal/hadoop/yarn_tr/check'
        ]
        'setup':
          '@rybajs/metal/hadoop/yarn_tr/setup'
        'start':
          '@rybajs/metal/hadoop/yarn_tr/start'
        'status':
          '@rybajs/metal/hadoop/yarn_tr/status'
        'stop':
          '@rybajs/metal/hadoop/yarn_tr/stop'

[tr]: https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServiceV2.html