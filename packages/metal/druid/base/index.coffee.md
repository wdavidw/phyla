
# Druid

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        yarn_client: module: '@rybajs/metal/hadoop/yarn_client', local: true, auto: true, implicit: true
        mapred_client: module: '@rybajs/metal/hadoop/mapred_client', local: true, auto: true, implicit: true
      configure:
        '@rybajs/metal/druid/base/configure'
      commands:
        'prepare':
          '@rybajs/metal/druid/base/prepare'
        'install':
          '@rybajs/metal/druid/base/install'
