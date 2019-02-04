
# Druid MiddleManager Server

The [middle manager] node is a worker node that executes submitted tasks. Middle Managers forward tasks to peons that run in separate JVMs. The reason we have separate JVMs for tasks is for resource and log isolation. Each Peon is capable of running only one task at a time, however, a middle manager may have multiple peons.

[Peons] run a single task in a single JVM. MiddleManager is responsible for creating Peons for running tasks. Peons should rarely (if ever for testing purposes) be run on their own.

[middle manager]: http://druid.io/docs/latest/design/middlemanager.html
[peons]: http://druid.io/docs/latest/design/peons.html

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        mapred_client: module: '@rybajs/metal/hadoop/mapred_client'
        druid: module: '@rybajs/metal/druid/base', local: true, auto: true, implicit: true
        druid_coordinator: module: '@rybajs/metal/druid/coordinator'
        druid_overlord: module: '@rybajs/metal/druid/overlord'
        druid_middlemanager: module: '@rybajs/metal/druid/middlemanager'
      configure:
        '@rybajs/metal/druid/middlemanager/configure'
      commands:
        'install': [
          '@rybajs/metal/druid/middlemanager/install'
          '@rybajs/metal/druid/middlemanager/start'
        ]
        'start':
          '@rybajs/metal/druid/middlemanager/start'
        'status':
          '@rybajs/metal/druid/middlemanager/status'
        'stop':
          '@rybajs/metal/druid/middlemanager/stop'
