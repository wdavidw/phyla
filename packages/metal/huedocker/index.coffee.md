
# Hue (Dockerized)

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
Starting from 3.7 Hue version
configuring hue following HDP [instructions][hdp-2.3.2.0-hue]

This module should be installed after having executed the prepare script.
It will build and copy to /@rybajs/metal/huedocker/resources the hue_docker.tar docker image to
beloaded to the target server
```
./bin/prepare
```

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', implicit: true, local: true
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true, require: true
        test_user: module: '@rybajs/metal/commons/test_user', implicit: true, local: true
        docker: module: 'masson/commons/docker', implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', required: true
        yarn_client: module: '@rybajs/metal/hadoop/yarn_client', implicit: true, local: true, local: true
        oozie_client: module: '@rybajs/metal/oozie/client', implicit: true, local: true
        hbase_client: module: '@rybajs/metal/hbase/client', implicit: true, local: true
        hbase_thrift: module: '@rybajs/metal/hbase/thrift'
        hive_client: module: '@rybajs/metal/hive/client', implicit: true, local: true
        hive_beeline: module: '@rybajs/metal/hive/beeline', implicit: true, local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', implicit: true, local: true
        hdfs_nn: '@rybajs/metal/hadoop/hdfs_nn'
        hdfs_dn: '@rybajs/metal/hadoop/hdfs_dn'
        yarn_rm: '@rybajs/metal/hadoop/yarn_rm'
        yarn_nm: '@rybajs/metal/hadoop/yarn_nm'
        mapred_jhs: '@rybajs/metal/hadoop/mapred_jhs'
        yarn_ts: '@rybajs/metal/hadoop/yarn_ts'
        httpfs: '@rybajs/metal/hadoop/httpfs'
        oozie_server: '@rybajs/metal/oozie/server'
        hive_server2: '@rybajs/metal/hive/server2'
        hive_webhcat: '@rybajs/metal/hive/webhcat'
        zookeeper_server: '@rybajs/metal/zookeeper/server'
        sqoop: '@rybajs/metal/sqoop'
        huedocker: '@rybajs/metal/huedocker'
      configure:
        '@rybajs/metal/huedocker/configure'
      commands:
        'install': [
          '@rybajs/metal/huedocker/install'
          '@rybajs/metal/huedocker/start'
          '@rybajs/metal/huedocker/check'
        ]
        'start':
          '@rybajs/metal/huedocker/start'
        'wait':
          '@rybajs/metal/huedocker/wait'
        'check':
          '@rybajs/metal/huedocker/check'
        'stop':
          '@rybajs/metal/huedocker/stop'
        'status':
          '@rybajs/metal/huedocker/status'
        'prepare':
          '@rybajs/metal/huedocker/prepare'


[home]: http://gethue.com
[hdp-2.3.2.0-hue]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/prerequisites_hue.html)
