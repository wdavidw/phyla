
# Druid Overlord

[Overlord] component manages task distribution to middle managers.

The [overlord] node is responsible for accepting tasks, coordinating task 
distribution, creating locks around tasks, and returning statuses to callers. 
[Overlord] can be configured to run in one of two modes - local or remote (local 
being default). In remote mode, the overlord and middle manager are run in 
separate processes and you can run each on a different server.

[overlord]: http://druid.io/docs/latest/design/indexing-service.html

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        # hdfs_client: module: 'ryba/hadoop/hdfs_client'
        # mapred_client: module: 'ryba/hadoop/mapred_client'
        druid: module: 'ryba/druid/base', local: true, auto: true, implicit: true
        # druid_coordinator: module: 'ryba/druid/coordinator'
        druid_overlord: module: 'ryba/druid/overlord'
        # druid_middlemanager: module: 'ryba/druid/middlemanager'
      configure:
        'ryba/druid/overlord/configure'
      commands:
        'prepare':
          'ryba/druid/prepare'
        'install': [
          'ryba/druid/overlord/install'
          'ryba/druid/overlord/start'
        ]
        'start':
          'ryba/druid/overlord/start'
        'status':
          'ryba/druid/overlord/status'
        'stop':
          'ryba/druid/overlord/stop'
