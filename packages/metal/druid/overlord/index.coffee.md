
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
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        # hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client'
        # mapred_client: module: '@rybajs/metal/hadoop/mapred_client'
        druid: module: '@rybajs/metal/druid/base', local: true, auto: true, implicit: true
        # druid_coordinator: module: '@rybajs/metal/druid/coordinator'
        druid_overlord: module: '@rybajs/metal/druid/overlord'
        # druid_middlemanager: module: '@rybajs/metal/druid/middlemanager'
      configure:
        '@rybajs/metal/druid/overlord/configure'
      commands:
        'install': [
          '@rybajs/metal/druid/overlord/install'
          '@rybajs/metal/druid/overlord/start'
        ]
        'start':
          '@rybajs/metal/druid/overlord/start'
        'status':
          '@rybajs/metal/druid/overlord/status'
        'stop':
          '@rybajs/metal/druid/overlord/stop'
