
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
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        mapred_client: module: 'ryba/hadoop/mapred_client', local: true, auto: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        tez: module: 'ryba/tez', local: true, auto: true, implicit: true
        hive_metastore: module: 'ryba/hive/metastore', local: true, auto: true, implicit: true
        hive_hcatalog: module: 'ryba/hive/hcatalog'
        hbase_client: module: 'ryba/hbase/client', local: true, recommanded: true
      configure:
        'ryba/hive/hcatalog/configure'
      commands:
        'install': ->
          options = @config.ryba.hive.hcatalog
          @call 'ryba/hive/hcatalog/install', options
          @call 'ryba/hive/hcatalog/start', options
          @call 'ryba/hive/hcatalog/check', options
        'check': ->
          options = @config.ryba.hive.hcatalog
          @call 'ryba/hive/hcatalog/check', options
        'start': ->
          options = @config.ryba.hive.hcatalog
          @call 'ryba/hive/hcatalog/start', options
        'status':
          'ryba/hive/hcatalog/status'
        'stop': ->
          options = @config.ryba.hive.hcatalog
          @call 'ryba/hive/hcatalog/stop', options
        'report': ->
          options = @config.ryba.hive.hcatalog
          @call 'masson/bootstrap/report'
          @call 'ryba/hive/hcatalog/report', options
        'backup': ->
          options = @config.ryba.hive.hcatalog
          @call 'ryba/hive/hcatalog/backup', options
