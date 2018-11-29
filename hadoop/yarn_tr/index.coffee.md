
# Yarn Timeline Reader

The [Yarn Timeline Reader][tr] new component shipped with YARN 3. Its role is to answer queries concerning
Jobs metadata.
The TimeLineService v1 has become v2 and is now divided into two parts in order to be scalable.
 - The Timeline Reader which can be high available.
 - The Timeline Writer which is embeeded in Yarn ResourceManagers and Yarn NodeManagers.

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
        yarn_rm: module: 'ryba/hadoop/yarn_rm', required: true
        yarn_tr: module: 'ryba/hadoop/yarn_tr'
        yarn_tr_hbase_embedded: module: 'ryba/hadoop/yarn_tr_hbase_embedded'
        yarn_tr_hbase_service: module: 'ryba/hadoop/yarn_tr_hbase_service'
        zookeeper: module: 'ryba/zookeeper/server'
      configure:
        'ryba/hadoop/yarn_tr/configure'
      commands:
        'check':
          'ryba/hadoop/yarn_tr/check'
        'install': [
          'ryba/hadoop/yarn_tr/install'
          'ryba/hadoop/yarn_tr/setup'
          'ryba/hadoop/yarn_tr/start'
          'ryba/hadoop/yarn_tr/check'
        ]
        'setup':
          'ryba/hadoop/yarn_tr/setup'
        'start':
          'ryba/hadoop/yarn_tr/start'
        'status':
          'ryba/hadoop/yarn_tr/status'
        'stop':
          'ryba/hadoop/yarn_tr/stop'

[tr]: https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServiceV2.html