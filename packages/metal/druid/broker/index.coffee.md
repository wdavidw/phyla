
# Druid Broker Server

The [Broker] is the node to route queries to if you want to run a distributed 
cluster. It understands the metadata published to ZooKeeper about what segments 
exist on what nodes and routes queries such that they hit the right nodes. This 
node also merges the result sets from all of the individual nodes together. On 
start up, Realtime nodes announce themselves and the segments they are serving 
in Zookeeper. 

broker: http://druid.io/docs/latest/design/broker.html

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        iptables: module: 'masson/core/iptables', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        druid: module: '@rybajs/metal/druid/base', local: true, auto: true, implicit: true
        druid_coordinator: module: '@rybajs/metal/druid/coordinator'
        druid_overlord: module: '@rybajs/metal/druid/overlord'
        druid_historical: module: '@rybajs/metal/druid/historical'
        druid_middlemanager: module: '@rybajs/metal/druid/middlemanager'
        druid_broker: module: '@rybajs/metal/druid/broker'
      configure:
        '@rybajs/metal/druid/broker/configure'
      commands:
        'check':
          '@rybajs/metal/druid/broker/check'
        'install': [
          '@rybajs/metal/druid/broker/install'
          '@rybajs/metal/druid/broker/start'
          '@rybajs/metal/druid/broker/check'
        ]
        'start':
          '@rybajs/metal/druid/broker/start'
        'status':
          '@rybajs/metal/druid/broker/status'
        'stop':
          '@rybajs/metal/druid/broker/stop'
