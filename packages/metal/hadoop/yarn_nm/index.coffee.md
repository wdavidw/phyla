
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
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', required: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn', required: true
        ranger_admin: module: '@rybajs/metal/ranger/admin'
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm'
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts', single: true
        yarn_tr: module: '@rybajs/metal/hadoop/yarn_tr'
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm', required: true
        metrics: module: '@rybajs/metal/metrics', local: true
      configure:
        '@rybajs/metal/hadoop/yarn_nm/configure'
      commands:
        # 'backup':
        #   '@rybajs/metal/hadoop/yarn_nm/backup'
        'check':
          '@rybajs/metal/hadoop/yarn_nm/check'
        'install': [
          'masson/core/info'
          '@rybajs/metal/hadoop/yarn_nm/install'
          '@rybajs/metal/hadoop/yarn_nm/start'
          '@rybajs/metal/hadoop/yarn_nm/check'
        ]
        'report': [
          'masson/bootstrap/report'
          '@rybajs/metal/hadoop/yarn_nm/report'
        ]
        'start':
          '@rybajs/metal/hadoop/yarn_nm/start'
        'status':
          '@rybajs/metal/hadoop/yarn_nm/status'
        'stop':
          '@rybajs/metal/hadoop/yarn_nm/stop'
