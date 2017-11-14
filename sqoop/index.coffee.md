
# Sqoop

[Apache Sqoop](http://sqoop.apache.org/) is a tool designed for efficiently transferring bulk data between
Apache Hadoop and structured datastores such as relational databases.

      module.exports =
        deps:
          krb5_client: module: 'masson/core/krb5_client', local: true, required: true
          java: module: 'masson/commons/java', local: true
          mysql_client: 'masson/commons/mysql/client'
          mariadb_client: 'masson/commons/mariadb/client'
          hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
          hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
          hive_client: module: 'ryba/hive/client', local: true, auto: true, implicit: true
          yarn_client: module: 'ryba/hadoop/yarn_client', local: true, auto: true, implicit: true
        configure:
          'ryba/sqoop/configure'
        commands:
          'install':
            'ryba/sqoop/install'
