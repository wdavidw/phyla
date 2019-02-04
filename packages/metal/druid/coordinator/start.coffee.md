
# Druid Coordinator Start

    module.exports = header: 'Druid Coordinator Start', handler: (options) ->

## Wait

      @call '@rybajs/metal/zookeeper/server/wait', once: true, options.wait_zookeeper_server

## Kerberos Ticket

      @krb5.ticket
        header: 'Kerberos Ticket'
        uid: options.user.name
        principal: options.krb5_service.principal
        keytab: options.krb5_service.keytab

## Service

      @service.start
        name: 'druid-coordinator'
      
## Assert TCP

      @connection.assert
        header: 'TCP'
        servers: options.wait.tcp.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000
