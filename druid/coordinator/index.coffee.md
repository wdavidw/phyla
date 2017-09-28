
# Druid Coordinator

The Druid [coordinator] node is primarily responsible for segment management and
distribution. More specifically, the Druid [coordinator] node communicates to
historical nodes to load or drop segments based on configurations. The Druid
[coordinator] is responsible for loading new segments, dropping outdated segments,
managing segment replication, and balancing segment load.

[coordinator]: http://druid.io/docs/latest/design/coordinator.html

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        # hdfs_client: module: 'ryba/hadoop/hdfs_client'
        # mapred_client: module: 'ryba/hadoop/mapred_client'
        druid: module: 'ryba/druid/base', local: true, auto: true, implicit: true
        druid_coordinator: module: 'ryba/druid/coordinator'
        # druid_overlord: module: 'ryba/druid/overlord'
        # druid_historical: module: 'ryba/druid/historical'
        # druid_middlemanager: module: 'ryba/druid/middlemanager'
        # druid_broker: module: 'ryba/druid/broker'
      configure:
        'ryba/druid/coordinator/configure'
      commands:
        'prepare': ->
          options = @config.ryba.druid.coordinator
          @call 'ryba/druid/prepare', options
        'install': ->
          options = @config.ryba.druid.coordinator
          @call 'ryba/druid/coordinator/install', options
          @call 'ryba/druid/coordinator/start', options
        'start': ->
          options = @config.ryba.druid.coordinator
          @call 'ryba/druid/coordinator/start', options
        'status':
          'ryba/druid/coordinator/status'
        'stop': ->
          options = @config.ryba.druid.coordinator
          @call 'ryba/druid/coordinator/stop', options
