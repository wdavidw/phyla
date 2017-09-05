
# Hive HCatalog

[HCatalog](https://cwiki.apache.org/confluence/display/Hive/HCatalog+UsingHCat) 
is a table and storage management layer for Hadoop that enables users with different 
data processing tools — Pig, MapReduce — to more easily read and write data on the grid.
 HCatalog’s table abstraction presents users with a relational view of data in the Hadoop
 distributed file system (HDFS) and ensures that users need not worry about where or in what
 format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        mapred_client: module: 'ryba/hadoop/mapred_client', implicit: true
        metastore: module: 'ryba/hive/metastore', implicit: true
        zookeeper_server: 'ryba/zookeeper/server'
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        tez: module: 'ryba/tez'
        hbase_client: implicit: true, module: 'ryba/hbase/client'
      configure:
        'ryba/hive/hcatalog/configure'
      commands:
        'install': [
          'ryba/hive/hcatalog/install'
          'ryba/hive/hcatalog/start'
          'ryba/hive/hcatalog/check'
        ]
        'check': [
          'ryba/hive/hcatalog/check'
        ]
        'start':
          'ryba/hive/hcatalog/start'
        'status':
          'ryba/hive/hcatalog/status'
        'stop':
          'ryba/hive/hcatalog/stop'
        'wait':
          'ryba/hive/hcatalog/wait'
        'report': [
          'masson/bootstrap/report'
          'ryba/hive/hcatalog/report'
        ]
        'backup':
          'ryba/hive/hcatalog/backup'
