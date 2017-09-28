
# Druid MiddleManager Start

    module.exports = header: 'Druid MiddleManager Start', label_true: 'STARTED', handler: (options) ->

## Wait

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @call 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn
      @call 'ryba/druid/coordinator/wait', once: true, options.wait_druid_coordinator
      @call 'ryba/druid/overlord/wait', once: true, options.wait_druid_overlord

## Kerberos Ticket

      @krb5.ticket
        header: 'Kerberos Ticket'
        uid: options.user.name
        principal: options.krb5_service.principal
        keytab: options.krb5_service.keytab

## Service

      @service.start
        header: 'Service'
        name: 'druid-middlemanager'
      
## Assert TCP

      @connection.assert
        header: 'TCP'
        servers: options.wait.tcp.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000
