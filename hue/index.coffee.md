
# Hue

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
a Zookeeper Browser and a SDK.

Link to configure [hive hue configuration][hive-hue-ssl] over ssl.

    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
        krb5_client: module: 'masson/core/krb5_client'
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
        krb5_user: implicit: true, module: 'ryba/commons/krb5_user'
        docker: implicit: true, module: 'masson/commons/docker'
        mysql_server: 'masson/commons/mysql/server'
        hdfs_client: implicit: true, module: 'ryba/hadoop/hdfs_client'
        yarn_client: implicit: true, module: 'ryba/hadoop/yarn_client'
        oozie_client: implicit: true, module: 'ryba/oozie/client'
        hbase_client: implicit: true, module: 'ryba/hbase/client'
        hive_client: implicit: true, module: 'ryba/hive/client'
        hadoop_core: implicit:true, module: 'ryba/hadoop/core'
        hdfs_nn: 'ryba/hadoop/hdfs_nn'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        hbase_thrift: 'ryba/hbase/thrift'
        spark_livy_servers: 'ryba/spark/livy_server'
        spark_thrift_server: 'ryba/spark/thrift_server'
        spark_history_servers: 'ryba/spark/history_server'
        mapred_jhs: 'ryba/hadoop/mapred_jhs'
        httpfs: 'ryba/hadoop/httpfs'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        oozie: 'ryba/oozie/server'
        server2: 'ryba/hive/server2'
        webhcat: 'ryba/hive/webhcat'
      configure:
        'ryba/hue/configure'
      commands:
        'backup': [
          'ryba/hue/backup'
        ]
        'install': [
          'masson/core/iptables'
          'masson/commons/mysql/client' # Install the mysql connector
          'masson/core/krb5_client' # Install kerberos clients to create/test new Hive principal
          'ryba/hadoop/hdfs_client/install' #Set java_home in "hadoop-env.sh"
          'ryba/hadoop/yarn_client/install'
          'ryba/hadoop/mapred_client/install'
          'ryba/hive/client/install' # Hue reference hive conf dir
          'ryba/pig/install'
          'ryba/hue/configure'
          'ryba/hue/install'
          'ryba/hue/start'
        ]
        'start': [
          'ryba/hue/start'
        ]
        'status': [
          'ryba/hue/status'
        ]
        'stop': [
          'ryba/hue/stop'
        ]

[home]: http://gethue.com
[hive-hue-ssl]:(http://www.cloudera.com/content/www/en-us/documentation/cdh/5-0-x/CDH5-Security-Guide/cdh5sg_hue_security.html)
