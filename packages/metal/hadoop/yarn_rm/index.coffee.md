
# YARN ResourceManager

[Yarn ResourceManager ](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html) is the central authority that manages resources and schedules applications running atop of YARN.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', required: true
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn', required: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn', required: true
        mapred_jhs: module: '@rybajs/metal/hadoop/mapred_jhs', single: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm'
        ranger_admin: module: '@rybajs/metal/ranger/admin'
        metrics: module: '@rybajs/metal/metrics', local: true
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/hadoop/yarn_rm/configure'
      commands:
        # 'backup':
        #   '@rybajs/metal/hadoop/yarn_rm/backup'
        'check':
          '@rybajs/metal/hadoop/yarn_rm/check'
        'report': [
          'masson/bootstrap/report'
          '@rybajs/metal/hadoop/yarn_rm/report'
        ]
        'install': [
          '@rybajs/metal/hadoop/yarn_rm/install'
          '@rybajs/metal/hadoop/yarn_rm/hbase_client'
          '@rybajs/metal/hadoop/yarn_rm/scheduler'
          '@rybajs/metal/hadoop/yarn_rm/start'
          '@rybajs/metal/hadoop/yarn_rm/check'
        ]
        'start':
          '@rybajs/metal/hadoop/yarn_rm/start'
        'status':
          '@rybajs/metal/hadoop/yarn_rm/status'
        'stop':
          '@rybajs/metal/hadoop/yarn_rm/stop'


[restart]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/ResourceManagerRestart.html
[ml_root_acl]: http://lucene.472066.n3.nabble.com/Yarn-HA-Zookeeper-ACLs-td4138735.html
[cloudera_ha]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_hag_rm_ha_config.html
[cloudera_wp]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_ha_yarn_work_preserving_recovery.html
[hdp_wp]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.4/bk_yarn_resource_mgt/content/ch_work-preserving_restart.html
[YARN-128]: https://issues.apache.org/jira/browse/YARN-128
[YARN-128-pdf]: https://issues.apache.org/jira/secure/attachment/12552867/RMRestartPhase1.pdf
[YARN-556]: https://issues.apache.org/jira/browse/YARN-556
[YARN-556-pdf]: https://issues.apache.org/jira/secure/attachment/12599562/Work%20Preserving%20RM%20Restart.pdf
