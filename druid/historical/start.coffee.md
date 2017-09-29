
# Druid Historical Start

    module.exports = header: 'Druid Historical Start', handler: (options) ->

## Wait

      @call once: true, 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call once: true, 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @call once: true, 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.hadoop_conf_dir
      @call once: true, 'ryba/druid/coordinator/wait', once: true, options.wait_druid_coordinator
      @call once: true, 'ryba/druid/overlord/wait', once: true, options.wait_druid_overlord

## Kerberos Ticket

      @krb5.ticket
        uid: "#{options.user.name}"
        principal: "#{options.krb5_service.principal}"
        keytab: "#{options.krb5_service.keytab}"

## Service

      @service.start
        name: 'druid-historical'
      
## Assert TCP

      @connection.assert
        header: 'TCP'
        servers: options.wait.tcp.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000
