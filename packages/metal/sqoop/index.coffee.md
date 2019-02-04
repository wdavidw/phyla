
# Sqoop

[Apache Sqoop](http://sqoop.apache.org/) is a tool designed for efficiently transferring bulk data between
Apache Hadoop and structured datastores such as relational databases.

      module.exports =
        deps:
          krb5_client: module: 'masson/core/krb5_client', local: true, required: true
          java: module: 'masson/commons/java', local: true
          mysql_client: 'masson/commons/mysql/client'
          mariadb_client: 'masson/commons/mariadb/client'
          hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
          hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
          hive_client: module: '@rybajs/metal/hive/client', local: true, auto: true, implicit: true
          yarn_client: module: '@rybajs/metal/hadoop/yarn_client', local: true, auto: true, implicit: true
        configure:
          '@rybajs/metal/sqoop/configure'
        commands:
          'install':
            '@rybajs/metal/sqoop/install'
