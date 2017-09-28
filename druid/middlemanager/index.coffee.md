
# Druid MiddleManager Server

The [middle manager] node is a worker node that executes submitted tasks. Middle Managers forward tasks to peons that run in separate JVMs. The reason we have separate JVMs for tasks is for resource and log isolation. Each Peon is capable of running only one task at a time, however, a middle manager may have multiple peons.

[Peons] run a single task in a single JVM. MiddleManager is responsible for creating Peons for running tasks. Peons should rarely (if ever for testing purposes) be run on their own.

[middle manager]: http://druid.io/docs/latest/design/middlemanager.html
[peons]: http://druid.io/docs/latest/design/peons.html

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        mapred_client: module: 'ryba/hadoop/mapred_client'
        druid: module: 'ryba/druid/base', local: true, auto: true, implicit: true
        druid_coordinator: module: 'ryba/druid/coordinator'
        druid_overlord: module: 'ryba/druid/overlord'
        druid_middlemanager: module: 'ryba/druid/middlemanager'
      configure:
        'ryba/druid/middlemanager/configure'
      commands:
        'prepare': ->
          options = @config.ryba.druid.middlemanager
          @call 'ryba/druid/prepare', options
        'install': ->
          options = @config.ryba.druid.middlemanager
          @call 'ryba/druid/middlemanager/install', options
          @call 'ryba/druid/middlemanager/start', options
        'start': ->
          options = @config.ryba.druid.middlemanager
          @call 'ryba/druid/middlemanager/start', options
        'status': ->
          'ryba/druid/middlemanager/status'
        'stop': ->
          options = @config.ryba.druid.middlemanager
          @call 'ryba/druid/middlemanager/stop', options
