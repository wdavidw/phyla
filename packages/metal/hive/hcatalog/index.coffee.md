
# Hive HCatalog

[HCatalog](https://cwiki.apache.org/confluence/display/Hive/HCatalog+UsingHCat) 
is a table and storage management layer for Hadoop that enables users with different 
data processing tools — Pig, MapReduce — to more easily read and write data on the grid.

HCatalog’s table abstraction presents users with a relational view of data in the Hadoop
distributed file system (HDFS) and ensures that users need not worry about where or in what
format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
        mapred_client: module: '@rybajs/metal/hadoop/mapred_client', local: true, auto: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm'
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm'
        tez: module: '@rybajs/metal/tez', local: true, auto: true, implicit: true
        hive_metastore: module: '@rybajs/metal/hive/metastore', local: true, auto: true, implicit: true
        hive_hcatalog: module: '@rybajs/metal/hive/hcatalog'
        hbase_client: module: '@rybajs/metal/hbase/client', local: true, recommanded: true
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/hive/hcatalog/configure'
      commands:
        'install': [
          '@rybajs/metal/hive/hcatalog/install'
          '@rybajs/metal/hive/hcatalog/start'
          '@rybajs/metal/hive/hcatalog/check'
        ]
        'check':
          '@rybajs/metal/hive/hcatalog/check'
        'start':
          '@rybajs/metal/hive/hcatalog/start'
        'status':
          '@rybajs/metal/hive/hcatalog/status'
        'stop':
          '@rybajs/metal/hive/hcatalog/stop'
        'report': [
          'masson/bootstrap/report'
          '@rybajs/metal/hive/hcatalog/report'
        ]
        'backup':
          '@rybajs/metal/hive/hcatalog/backup'
