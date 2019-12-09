
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
        db_admin: implicit: true, module: '@rybajs/metal/commons/db_admin'
        test_user: implicit: true, module: '@rybajs/metal/commons/test_user'
        docker: implicit: true, module: 'masson/commons/docker'
        mysql_server: 'masson/commons/mysql/server'
        hdfs_client: implicit: true, module: '@rybajs/metal/hadoop/hdfs_client'
        yarn_client: implicit: true, module: '@rybajs/metal/hadoop/yarn_client'
        oozie_client: implicit: true, module: '@rybajs/metal/oozie/client'
        hbase_client: implicit: true, module: '@rybajs/metal/hbase/client'
        hive_client: implicit: true, module: '@rybajs/metal/hive/client'
        hadoop_core: implicit:true, module: '@rybajs/metal/hadoop/core'
        hdfs_nn: '@rybajs/metal/hadoop/hdfs_nn'
        yarn_rm: '@rybajs/metal/hadoop/yarn_rm'
        hbase_thrift: '@rybajs/metal/hbase/thrift'
        spark_livy_servers: '@rybajs/metal/spark/livy_server'
        spark_thrift_server: '@rybajs/metal/spark/thrift_server'
        spark_history_servers: '@rybajs/metal/spark/history_server'
        mapred_jhs: '@rybajs/metal/hadoop/mapred_jhs'
        httpfs: '@rybajs/metal/hadoop/httpfs'
        yarn_rm: '@rybajs/metal/hadoop/yarn_rm'
        oozie: '@rybajs/metal/oozie/server'
        server2: '@rybajs/metal/hive/server2'
        webhcat: '@rybajs/metal/hive/webhcat'
      configure:
        '@rybajs/metal/hue/configure'
      commands:
        'backup': [
          '@rybajs/metal/hue/backup'
        ]
        'install': [
          'masson/core/iptables'
          'masson/commons/mysql/client' # Install the mysql connector
          'masson/core/krb5_client' # Install kerberos clients to create/test new Hive principal
          '@rybajs/metal/hadoop/hdfs_client/install' #Set java_home in "hadoop-env.sh"
          '@rybajs/metal/hadoop/yarn_client/install'
          '@rybajs/metal/hadoop/mapred_client/install'
          '@rybajs/metal/hive/client/install' # Hue reference hive conf dir
          '@rybajs/metal/pig/install'
          '@rybajs/metal/hue/configure'
          '@rybajs/metal/hue/install'
          '@rybajs/metal/hue/start'
        ]
        'start': [
          '@rybajs/metal/hue/start'
        ]
        'status': [
          '@rybajs/metal/hue/status'
        ]
        'stop': [
          '@rybajs/metal/hue/stop'
        ]

[home]: http://gethue.com
[hive-hue-ssl]:(http://www.cloudera.com/content/www/en-us/documentation/cdh/5-0-x/CDH5-Security-Guide/cdh5sg_hue_security.html)
