
# Hive Metastore

Hive Metastore is a middleware for persisting and accessing Hadoop metadata.
Apache Impala, Spark, Drill, Presto, and other systems all use Hive’s metastore. 
Some, like Impala and Presto can use it as their own metadata system with the
rest of Hive not present.

Metastore’s table abstraction presents users with a relational view of data in the Hadoop
distributed file system (HDFS) and ensures that users need not worry about where or in what
format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

    module.exports =
      deps:
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
      configure:
        '@rybajs/metal/hive/metastore/configure'
      commands:
        'install':
          '@rybajs/metal/hive/metastore/install'
        'backup':
          '@rybajs/metal/hive/metastore/backup'
