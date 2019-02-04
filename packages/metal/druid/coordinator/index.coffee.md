
# Druid Coordinator

The Druid [coordinator] node is primarily responsible for segment management and
distribution. More specifically, the Druid [coordinator] node communicates to
historical nodes to load or drop segments based on configurations. The Druid
[coordinator] is responsible for loading new segments, dropping outdated segments,
managing segment replication, and balancing segment load.

[coordinator]: http://druid.io/docs/latest/design/coordinator.html

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        # hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client'
        # mapred_client: module: '@rybajs/metal/hadoop/mapred_client'
        druid: module: '@rybajs/metal/druid/base', local: true, auto: true, implicit: true
        druid_coordinator: module: '@rybajs/metal/druid/coordinator'
        # druid_overlord: module: '@rybajs/metal/druid/overlord'
        # druid_historical: module: '@rybajs/metal/druid/historical'
        # druid_middlemanager: module: '@rybajs/metal/druid/middlemanager'
        # druid_broker: module: '@rybajs/metal/druid/broker'
      configure:
        '@rybajs/metal/druid/coordinator/configure'
      commands:
        'install': [
          '@rybajs/metal/druid/coordinator/install'
          '@rybajs/metal/druid/coordinator/start'
        ]
        'start':
          '@rybajs/metal/druid/coordinator/start'
        'status':
          '@rybajs/metal/druid/coordinator/status'
        'stop':
          '@rybajs/metal/druid/coordinator/stop'
