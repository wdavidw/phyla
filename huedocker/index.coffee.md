
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
        iptables: module: 'masson/core/iptables', implicit: true, local: true
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true, require: true
        test_user: module: 'ryba/commons/test_user', implicit: true, local: true
        docker: module: 'masson/commons/docker', implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', required: true
        yarn_client: module: 'ryba/hadoop/yarn_client', implicit: true, local: true, local: true
        oozie_client: module: 'ryba/oozie/client', implicit: true, local: true
        hbase_client: module: 'ryba/hbase/client', implicit: true, local: true
        hbase_thrift: module: 'ryba/hbase/thrift'
        hive_client: module: 'ryba/hive/client', implicit: true, local: true
        hive_beeline: module: 'ryba/hive/beeline', implicit: true, local: true
        hadoop_core: module: 'ryba/hadoop/core', implicit: true, local: true
        hdfs_nn: 'ryba/hadoop/hdfs_nn'
        hdfs_dn: 'ryba/hadoop/hdfs_dn'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        yarn_nm: 'ryba/hadoop/yarn_nm'
        mapred_jhs: 'ryba/hadoop/mapred_jhs'
        httpfs: 'ryba/hadoop/httpfs'
        oozie_server: 'ryba/oozie/server'
        hive_server2: 'ryba/hive/server2'
        hive_webhcat: 'ryba/hive/webhcat'
        zookeeper_server: 'ryba/zookeeper/server'
        sqoop: 'ryba/sqoop'
        huedocker: 'ryba/huedocker'
      configure: 'ryba/huedocker/configure'
      commands:
        'install': ->
          options = @config.ryba.hue_docker
          @call 'ryba/huedocker/install', options
          @call 'ryba/huedocker/start', options
          @call 'ryba/huedocker/check', options
        'start': ->
          options = @config.ryba.hue_docker
          @call 'ryba/huedocker/start', options
        'wait': ->
          options = @config.ryba.hue_docker
          @call 'ryba/huedocker/wait', options
        'check': ->
          options = @config.ryba.hue_docker
          @call 'ryba/huedocker/check', options
        'stop': ->
          options = @config.ryba.hue_docker
          @call 'ryba/huedocker/stop', options
        'status': ->
          options = @config.ryba.hue_docker
          @call 'ryba/huedocker/status', options
        'prepare': ->
          options = @config.ryba.hue_docker
          options.ssh = null
          @call 'ryba/huedocker/prepare', options


[home]: http://gethue.com
[hdp-2.3.2.0-hue]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/prerequisites_hue.html)
