
# YARN NodeManager

[The NodeManager](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.htm) (NM) is YARN’s per-node agent,
and takes care of the individual
computing nodes in a Hadoop cluster. This includes keeping up-to date with the
ResourceManager (RM), overseeing containers’ life-cycle management; monitoring
resource usage (memory, CPU) of individual containers, tracking node-health,
log’s management and auxiliary services which may be exploited by different YARN
applications.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        cgroups: module: 'masson/core/cgroups', local: true, required: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', required: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', required: true
        ranger_admin: module: 'ryba/ranger/admin'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
      configure:
        'ryba/hadoop/yarn_nm/configure'
        # 'ryba/ranger/plugins/yarn/configure'
      commands:
        # 'backup': 'ryba/hadoop/yarn_nm/backup'
        'check': ->
          options = @config.ryba.yarn.nm
          @call 'ryba/hadoop/yarn_nm/check', options
        'install': ->
          options = @config.ryba.yarn.nm
          @call 'masson/core/info'
          @call 'ryba/hadoop/yarn_nm/install', options
          @call 'ryba/hadoop/yarn_nm/start', options
          @call 'ryba/hadoop/yarn_nm/check', options
        'report': ->
          options = @config.ryba.yarn.nm
          @call 'masson/bootstrap/report'
          @call 'ryba/hadoop/yarn_nm/report', options
        'start': ->
          options = @config.ryba.yarn.nm
          @call 'ryba/hadoop/yarn_nm/start', options
        'status':
          'ryba/hadoop/yarn_nm/status'
        'stop': ->
          options = @config.ryba.yarn.nm
          @call 'ryba/hadoop/yarn_nm/stop', options
