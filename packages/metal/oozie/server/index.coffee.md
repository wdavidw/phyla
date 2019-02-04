
# Oozie Server

[Oozie Server][Oozie] is a server based Workflow Engine specialized in running workflow jobs.
Workflows are basically collections of actions.
These actions can be  Hadoop Map/Reduce jobs, Pig jobs arranged in a control dependency DAG (Direct Acyclic Graph).
Please check Oozie page

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true
        hdfs_client_local: module: '@rybajs/metal/hadoop/hdfs_client', local: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client'
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn'
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm'
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm'
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts'
        yarn_tr: module: '@rybajs/metal/hadoop/yarn_tr'
        mapred_jhs: module: '@rybajs/metal/hadoop/mapred_jhs'
        hbase_master: module: '@rybajs/metal/hbase/master'
        hive_hcatalog: module: '@rybajs/metal/hive/hcatalog'
        hive_server2: module: '@rybajs/metal/hive/server2'
        hive_webhcat: module: '@rybajs/metal/hive/webhcat'
        spark_client: module: '@rybajs/metal/spark2/client', local: true, auto: true, implicit: true
        oozie_server: module: '@rybajs/metal/oozie/server'
        log4j: module: '@rybajs/metal/log4j', local: true
      configure: '@rybajs/metal/oozie/server/configure'
      commands:
        backup:
          '@rybajs/metal/oozie/server/backup'
        install: [
          '@rybajs/metal/oozie/server/install'
          '@rybajs/metal/oozie/server/start'
          '@rybajs/metal/oozie/server/check'
        ]
        start:
          '@rybajs/metal/oozie/server/start'
        status:
          '@rybajs/metal/oozie/server/status'
        stop:
          '@rybajs/metal/oozie/server/stop'

[Oozie]: https://oozie.apache.org/docs/3.1.3-incubating/index.html
