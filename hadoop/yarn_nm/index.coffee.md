
# YARN NodeManager

[The NodeManager](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.htm) (NM) is YARN’s per-node agent,
and takes care of the individual
computing nodes in a Hadoop cluster. This includes keeping up-to date with the
ResourceManager (RM), overseeing containers’ life-cycle management; monitoring
resource usage (memory, CPU) of individual containers, tracking node-health,
log’s management and auxiliary services which may be exploited by different YARN
applications.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        cgroups: module: 'masson/core/cgroups', local: true, required: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', required: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', required: true
        ranger_admin: module: 'ryba/ranger/admin'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        yarn_ts: module: 'ryba/hadoop/yarn_ts', single: true
        yarn_tr: module: 'ryba/hadoop/yarn_tr'
        yarn_rm: module: 'ryba/hadoop/yarn_rm', required: true
        metrics: module: 'ryba/metrics', local: true
      configure:
        'ryba/hadoop/yarn_nm/configure'
      commands:
        # 'backup':
        #   'ryba/hadoop/yarn_nm/backup'
        'check':
          'ryba/hadoop/yarn_nm/check'
        'install': [
          'masson/core/info'
          'ryba/hadoop/yarn_nm/install'
          'ryba/hadoop/yarn_nm/start'
          'ryba/hadoop/yarn_nm/check'
        ]
        'report': [
          'masson/bootstrap/report'
          'ryba/hadoop/yarn_nm/report'
        ]
        'start':
          'ryba/hadoop/yarn_nm/start'
        'status':
          'ryba/hadoop/yarn_nm/status'
        'stop':
          'ryba/hadoop/yarn_nm/stop'
