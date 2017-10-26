
# Ryba Monitoring

This module contains configuration for nagios-like monitoring projects.
It supports:
* nagios   
* shinken   
* alignak   

    module.exports =
      use:
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
        poller: 'ryba/shinken/poller'
        # List of monitored services
        mysql_server: 'masson/commons/mysql/server'
        elasticsearch: 'ryba/elasticsearch'
        esdocker: 'ryba/esdocker'
        falcon: 'ryba/falcon'
        flume: 'ryba/flume'
        hdfs_client: 'ryba/hadoop/hdfs_client'
        hdfs_dn: 'ryba/hadoop/hdfs_dn'
        hdfs_jn: 'ryba/hadoop/hdfs_jn'
        hdfs_nn: 'ryba/hadoop/hdfs_nn'
        httpfs: 'ryba/hadoop/httpfs'
        mapred_client: 'ryba/hadoop/mapred_client'
        mapred_jhs: 'ryba/hadoop/mapred_jhs'
        yarn_client: 'ryba/hadoop/yarn_client'
        yarn_nm: 'ryba/hadoop/yarn_nm'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        yarn_ts: 'ryba/hadoop/yarn_ts'
        zkfc: 'ryba/hadoop/zkfc'
        hbase_client: 'ryba/hbase/client'
        hbase_master: 'ryba/hbase/master'
        hbase_regionserver: 'ryba/hbase/regionserver'
        hbase_rest: 'ryba/hbase/rest'
        hive_client: 'ryba/hive/client'
        hcatalog: 'ryba/hive/hcatalog'
        hiveserver2: 'ryba/hive/server2'
        webhcat: 'ryba/hive/webhcat'
        hue: 'ryba/huedocker'
        kafka_broker: 'ryba/kafka/broker'
        kafka_consumer: 'ryba/kafka/consumer'
        kafka_producer: 'ryba/kafka/producer'
        knox: 'ryba/knox/server'
        oozie_client: 'ryba/oozie/client'
        oozie_server: 'ryba/oozie/server'
        opentsdb: 'ryba/opentsdb'
        phoenix_client: 'ryba/phoenix/client'
        phoenix_master: 'ryba/phoenix/master'
        phoenix_regionserver: 'ryba/phoenix/regionserver'
        ranger: 'ryba/ranger/admin'
        rexster: 'ryba/rexster'
        spark_client: 'ryba/spark/client'
        spark_hs: 'ryba/spark/history_server'
        sqoop: 'ryba/sqoop'
        tez: 'ryba/tez'
        zookeeper_client: 'ryba/zookeeper/client'
        zookeeper_server: 'ryba/zookeeper/server'
        nifi: 'ryba/nifi'
      configure:
        'ryba/commons/monitoring/configure'
