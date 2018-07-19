
# Druid Historical Server

[Druid](http://www.druid.io) is a high-performance, column-oriented, distributed 
data store.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        # yarn_client: module: 'ryba/hadoop/yarn_client', local: true, auto: true, implicit: true
        # mapred_client: module: 'ryba/hadoop/mapred_client', local: true, auto: true, implicit: true
        druid: module: 'ryba/druid/base', local: true, auto: true, implicit: true
        druid_coordinator: module: 'ryba/druid/coordinator'
        druid_overlord: module: 'ryba/druid/overlord'
        druid_historical: module: 'ryba/druid/historical'
        # druid_middlemanager: module: 'ryba/druid/middlemanager'
        # druid_broker: module: 'ryba/druid/broker'
      configure:
        'ryba/druid/historical/configure'
      commands:
        'install': [
          'ryba/druid/historical/install'
          'ryba/druid/historical/start'
        ]
        'start':
          'ryba/druid/historical/start'
        'status':
          'ryba/druid/historical/status'
        'stop':
          'ryba/druid/historical/stop'
