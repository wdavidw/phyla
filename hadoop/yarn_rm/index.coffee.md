
# YARN ResourceManager

[Yarn ResourceManager ](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html) is the central authority that manages resources and schedules applications running atop of YARN.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hdfs_client: module: 'ryba/hadoop/hdfs_client', required: true
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn', required: true
        mapred_jhs: module: 'ryba/hadoop/mapred_jhs', single: true
        yarn_ts: module: 'ryba/hadoop/yarn_ts', single: true
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        ranger_admin: module: 'ryba/ranger/admin'
      configure:
        'ryba/hadoop/yarn_rm/configure'
        # 'ryba/ranger/plugins/yarn/configure'
      commands:
        # 'backup': 'ryba/hadoop/yarn_rm/backup'
        'check': ->
          options = @config.ryba.yarn.rm
          'ryba/hadoop/yarn_rm/check'
        'report': ->
          options = @config.ryba.yarn.rm
          @call 'masson/bootstrap/report'
          @call 'ryba/hadoop/yarn_rm/report', options
        'install': ->
          options = @config.ryba.yarn.rm
          @call 'ryba/hadoop/yarn_rm/install', options
          @call 'ryba/hadoop/yarn_rm/scheduler', options
          @call 'ryba/hadoop/yarn_rm/start', options
          @call 'ryba/hadoop/yarn_rm/check', options
        'start': ->
          options = @config.ryba.yarn.rm
          @call 'ryba/hadoop/yarn_rm/start', options
        'status':
          'ryba/hadoop/yarn_rm/status'
        'stop': ->
          options = @config.ryba.yarn.rm
          @call 'ryba/hadoop/yarn_rm/stop', options


[restart]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html
[ml_root_acl]: http://lucene.472066.n3.nabble.com/Yarn-HA-Zookeeper-ACLs-td4138735.html
[cloudera_ha]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_rm_ha_config.html
[cloudera_wp]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_ha_yarn_work_preserving_recovery.html
[hdp_wp]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/bk_yarn_resource_mgt/content/ch_work-preserving_restart.html
[YARN-128]: https://issues.apache.org/jira/browse/YARN-128
[YARN-128-pdf]: https://issues.apache.org/jira/secure/attachment/12552867/RMRestartPhase1.pdf
[YARN-556]: https://issues.apache.org/jira/browse/YARN-556
[YARN-556-pdf]: https://issues.apache.org/jira/secure/attachment/12599562/Work%20Preserving%20RM%20Restart.pdf
