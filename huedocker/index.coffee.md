
# Hue (Dockerized)

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
Starting from 3.7 Hue version
configuring hue following HDP [instructions][hdp-2.3.2.0-hue]

This module should be installed after having executed the prepare script.
It will build and copy to /ryba/huedocker/resources the hue_docker.tar docker image to
beloaded to the target server
```
./bin/prepare
```

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', implicit: true
        krb5_client: module: 'masson/core/krb5_client'
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        test_user: module: 'ryba/commons/test_user', implicit: true
        docker: module: 'masson/commons/docker', implicit: true
        mysql_server: 'masson/commons/mysql/server'
        hdfs_client: module: 'ryba/hadoop/hdfs_client', implicit: true
        yarn_client: module: 'ryba/hadoop/yarn_client', implicit: true
        oozie_client: module: 'ryba/oozie/client', implicit: true
        hbase_client: module: 'ryba/hbase/client', implicit: true
        hbase_thrift: module: 'ryba/hbase/thrift'
        hive_client: module: 'ryba/hive/client', implicit: true
        hadoop_core: module: 'ryba/hadoop/core', implicit: true
        hdfs_nn: 'ryba/hadoop/hdfs_nn'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        spark_livy_servers: 'ryba/spark/livy_server'
        spark_thrift_server: 'ryba/spark/thrift_server'
        spark_history_servers: 'ryba/spark/history_server'
        mapred_jhs: 'ryba/hadoop/mapred_jhs'
        httpfs: 'ryba/hadoop/httpfs'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        oozie: 'ryba/oozie/server'
        server2: 'ryba/hive/server2'
        webhcat: 'ryba/hive/webhcat'
      configure: 'ryba/huedocker/configure'
      commands:
        'install': [
          'ryba/huedocker/install'
          'ryba/huedocker/start'
          'ryba/huedocker/check'
        ]
        'start':
          'ryba/huedocker/start'
        'check':
          'ryba/huedocker/check'
        'wait':
          'ryba/huedocker/wait'
        'stop':
          'ryba/huedocker/stop'
        'status':
          'ryba/huedocker/status'
        'prepare':
          'ryba/huedocker/prepare'


[home]: http://gethue.com
[hdp-2.3.2.0-hue]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/prerequisites_hue.html)
