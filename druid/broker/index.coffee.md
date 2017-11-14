
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
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        druid: module: 'ryba/druid/base', local: true, auto: true, implicit: true
        druid_coordinator: module: 'ryba/druid/coordinator'
        druid_overlord: module: 'ryba/druid/overlord'
        druid_historical: module: 'ryba/druid/historical'
        druid_middlemanager: module: 'ryba/druid/middlemanager'
        druid_broker: module: 'ryba/druid/broker'
      configure:
        'ryba/druid/broker/configure'
      commands:
        'check':
          'ryba/druid/broker/check'
        'prepare':
          'ryba/druid/prepare'
        'install': [
          'ryba/druid/broker/install'
          'ryba/druid/broker/start'
          'ryba/druid/broker/check'
        ]
        'start':
          'ryba/druid/broker/start'
        'status':
          'ryba/druid/broker/status'
        'stop':
          'ryba/druid/broker/stop'
