
# Druid Broker Start

    module.exports = header: 'Druid Broker Start', label_true: 'STARTED', handler: (options) ->

## Wait

      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @call 'ryba/druid/coordinator/wait', once: true, options.wait_druid_coordinator
      @call 'ryba/druid/overlord/wait', once: true, options.wait_druid_overlord
      @call 'ryba/druid/historical/wait', once: true, options.wait_druid_historical
      @call 'ryba/druid/middlemanager/wait', once: true, options.wait_druid_middlemanager

## Kerberos Ticket

      @krb5.ticket
        header: 'Kerberos Ticket'
        uid: "#{options.user.name}"
        principal: "#{options.krb5_service.principal}"
        keytab: "#{options.krb5_service.keytab}"

## Service

      @service.start
        header: 'Service'
        name: 'druid-broker'
      
## Assert TCP

      @connection.assert
        header: 'TCP'
        servers: options.wait.tcp.filter (server) -> server.host is options.fqdn
        retry: 5
        sleep: 5000
