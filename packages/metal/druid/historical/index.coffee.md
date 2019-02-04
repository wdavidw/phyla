
# Druid Historical Server

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        # yarn_client: module: '@rybajs/metal/hadoop/yarn_client', local: true, auto: true, implicit: true
        # mapred_client: module: '@rybajs/metal/hadoop/mapred_client', local: true, auto: true, implicit: true
        druid: module: '@rybajs/metal/druid/base', local: true, auto: true, implicit: true
        druid_coordinator: module: '@rybajs/metal/druid/coordinator'
        druid_overlord: module: '@rybajs/metal/druid/overlord'
        druid_historical: module: '@rybajs/metal/druid/historical'
        # druid_middlemanager: module: '@rybajs/metal/druid/middlemanager'
        # druid_broker: module: '@rybajs/metal/druid/broker'
      configure:
        '@rybajs/metal/druid/historical/configure'
      commands:
        'install': [
          '@rybajs/metal/druid/historical/install'
          '@rybajs/metal/druid/historical/start'
        ]
        'start':
          '@rybajs/metal/druid/historical/start'
        'status':
          '@rybajs/metal/druid/historical/status'
        'stop':
          '@rybajs/metal/druid/historical/stop'
