
# Hive Metastore

Hive Metastore is a middleware for persisting and accessing Hadoop metadata.
Apache Impala, Spark, Drill, Presto, and other systems all use Hive’s metastore. 
Some, like Impala and Presto can use it as their own metadata system with the
rest of Hive not present.

Metastore’s table abstraction presents users with a relational view of data in the Hadoop
distributed file system (HDFS) and ensures that users need not worry about where or in what
format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

    module.exports =
      use:
        postgres_server: module: 'masson/commons/postgres/server'
        mariadb_server: module: 'masson/commons/mariadb/server'
        mysql_server: module: 'masson/commons/mysql/server'
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
      configure:
        'ryba/hive/metastore/configure'
      commands:
        'install': [
          'ryba/hive/metastore/install'
        ]
        'backup': 'ryba/hive/metastore/backup'
