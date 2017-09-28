
# Druid

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        yarn_client: module: 'ryba/hadoop/yarn_client', local: true, auto: true, implicit: true
        mapred_client: module: 'ryba/hadoop/mapred_client', local: true, auto: true, implicit: true
      configure:
        'ryba/druid/base/configure'
      commands:
        'prepare': ->
          options = @config.ryba.druid.base
          @call 'ryba/druid/base/prepare', options
        'install': ->
          options = @config.ryba.druid.base
          @call 'ryba/druid/base/install', options
