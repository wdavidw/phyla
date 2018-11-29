
# Ryba Monitoring

This module contains configuration for nagios-like monitoring projects.
It supports:
* nagios   
* shinken   
* alignak   

    module.exports =
      deps:
        db_admin: module: implicit: module: true, module: 'ryba/commons/db_admin'
        # List of monitored services
        mysql_server: module: 'masson/commons/mysql/server'
        elasticsearch: module: 'ryba/elasticsearch'
        esdocker: module: 'ryba/esdocker'
        falcon: module: 'ryba/falcon'
        flume: module: 'ryba/flume'
        hdfs_client: module: 'ryba/hadoop/hdfs_client'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
        hdfs_jn: module: 'ryba/hadoop/hdfs_jn'
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        httpfs: module: 'ryba/hadoop/httpfs'
        mapred_client: module: 'ryba/hadoop/mapred_client'
        mapred_jhs: module: 'ryba/hadoop/mapred_jhs'
        yarn_client: module: 'ryba/hadoop/yarn_client'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_ts: module: 'ryba/hadoop/yarn_ts'
        zkfc: module: 'ryba/hadoop/zkfc'
        hbase_client: module: 'ryba/hbase/client'
        hbase_master: module: 'ryba/hbase/master'
        hbase_regionserver: module: 'ryba/hbase/regionserver'
        hbase_rest: module: 'ryba/hbase/rest'
        hive_client: module: 'ryba/hive/client'
        hcatalog: module: 'ryba/hive/hcatalog'
        hiveserver2: module: 'ryba/hive/server2'
        webhcat: module: 'ryba/hive/webhcat'
        hue: module: 'ryba/huedocker'
        kafka_broker: module: 'ryba/kafka/broker'
        kafka_consumer: module: 'ryba/kafka/consumer'
        kafka_producer: module: 'ryba/kafka/producer'
        knox: module: 'ryba/knox/server'
        oozie_client: module: 'ryba/oozie/client'
        oozie_server: module: 'ryba/oozie/server'
        opentsdb: module: 'ryba/opentsdb'
        phoenix_client: module: 'ryba/phoenix/client'
        phoenix_master: module: 'ryba/phoenix/master'
        phoenix_regionserver: module: 'ryba/phoenix/regionserver'
        ranger: module: 'ryba/ranger/admin'
        rexster: module: 'ryba/rexster'
        spark_client: module: 'ryba/spark2/client'
        spark_hs: module: 'ryba/spark2/history_server'
        sqoop: module: 'ryba/sqoop'
        tez: module: 'ryba/tez'
        zookeeper_client: module: 'ryba/zookeeper/client'
        zookeeper_server: module: 'ryba/zookeeper/server'
        nifi: module: 'ryba/nifi'
      configure: 'ryba/commons/monitoring/configure'
