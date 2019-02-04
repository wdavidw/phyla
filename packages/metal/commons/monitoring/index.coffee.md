
# Ryba Monitoring

This module contains configuration for nagios-like monitoring projects.
It supports:
* nagios   
* shinken   
* alignak   

    module.exports =
      deps:
        db_admin: module: implicit: module: true, module: '@rybajs/metal/commons/db_admin'
        # List of monitored services
        mysql_server: module: 'masson/commons/mysql/server'
        elasticsearch: module: '@rybajs/metal/elasticsearch'
        esdocker: module: '@rybajs/metal/esdocker'
        falcon: module: '@rybajs/metal/falcon'
        flume: module: '@rybajs/metal/flume'
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client'
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn'
        hdfs_jn: module: '@rybajs/metal/hadoop/hdfs_jn'
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        httpfs: module: '@rybajs/metal/hadoop/httpfs'
        mapred_client: module: '@rybajs/metal/hadoop/mapred_client'
        mapred_jhs: module: '@rybajs/metal/hadoop/mapred_jhs'
        yarn_client: module: '@rybajs/metal/hadoop/yarn_client'
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm'
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm'
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts'
        zkfc: module: '@rybajs/metal/hadoop/zkfc'
        hbase_client: module: '@rybajs/metal/hbase/client'
        hbase_master: module: '@rybajs/metal/hbase/master'
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver'
        hbase_rest: module: '@rybajs/metal/hbase/rest'
        hive_client: module: '@rybajs/metal/hive/client'
        hcatalog: module: '@rybajs/metal/hive/hcatalog'
        hiveserver2: module: '@rybajs/metal/hive/server2'
        webhcat: module: '@rybajs/metal/hive/webhcat'
        hue: module: '@rybajs/metal/huedocker'
        kafka_broker: module: '@rybajs/metal/kafka/broker'
        kafka_consumer: module: '@rybajs/metal/kafka/consumer'
        kafka_producer: module: '@rybajs/metal/kafka/producer'
        knox: module: '@rybajs/metal/knox/server'
        oozie_client: module: '@rybajs/metal/oozie/client'
        oozie_server: module: '@rybajs/metal/oozie/server'
        opentsdb: module: '@rybajs/metal/opentsdb'
        phoenix_client: module: '@rybajs/metal/phoenix/client'
        phoenix_master: module: '@rybajs/metal/phoenix/master'
        phoenix_regionserver: module: '@rybajs/metal/phoenix/regionserver'
        ranger: module: '@rybajs/metal/ranger/admin'
        rexster: module: '@rybajs/metal/rexster'
        spark_client: module: '@rybajs/metal/spark2/client'
        spark_hs: module: '@rybajs/metal/spark2/history_server'
        sqoop: module: '@rybajs/metal/sqoop'
        tez: module: '@rybajs/metal/tez'
        zookeeper_client: module: '@rybajs/metal/zookeeper/client'
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        nifi: module: '@rybajs/metal/nifi'
      configure: '@rybajs/metal/commons/monitoring/configure'
