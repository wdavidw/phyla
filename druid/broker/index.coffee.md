
# Druid Broker Server

The [Broker] is the node to route queries to if you want to run a distributed 
cluster. It understands the metadata published to ZooKeeper about what segments 
exist on what nodes and routes queries such that they hit the right nodes. This 
node also merges the result sets from all of the individual nodes together. On 
start up, Realtime nodes announce themselves and the segments they are serving 
in Zookeeper. 

broker: http://druid.io/docs/latest/design/broker.html

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        druid: module: 'ryba/druid/base', local: true, auto: true, implicit: true
        druid_coordinator: module: 'ryba/druid/coordinator'
        druid_overlord: module: 'ryba/druid/overlord'
        druid_historical: module: 'ryba/druid/historical'
        druid_middlemanager: module: 'ryba/druid/middlemanager'
        druid_broker: module: 'ryba/druid/broker'
      configure:
        'ryba/druid/broker/configure'
      commands:
        check: ->
          options = @config.ryba.druid.broker
          @call 'ryba/druid/broker/check', options
        prepare: ->
          options = @config.ryba.druid.broker
          @call 'ryba/druid/prepare', options
        install: ->
          options = @config.ryba.druid.broker
          @call 'ryba/druid/broker/install', options
          @call 'ryba/druid/broker/start', options
          @call 'ryba/druid/broker/check', options
        start: ->
          options = @config.ryba.druid.broker
          @call 'ryba/druid/broker/start', options
        status:
          'ryba/druid/broker/status'
        stop: ->
          options = @config.ryba.druid.broker
          @call 'ryba/druid/broker/stop', options
