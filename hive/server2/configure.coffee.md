
# HiveServer2 Configuration

The following properties are required by knox in secured mode:

*   hive.server2.enable.doAs
*   hive.server2.allow.user.substitution
*   hive.server2.transport.mode
*   hive.server2.thrift.http.port
*   hive.server2.thrift.http.path

Example:

```json
{ "ryba": {
    "hive": {
      "server2": {
        "heapsize": "4096",
        "opts": "-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=130.98.196.54 -Dcom.sun.management.jmxremote.rmi.port=9526 -Dcom.sun.management.jmxremote.port=9526 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
      },
      "site": {
        "hive.server2.thrift.port": "10001"
      }
    }
} }
```

    module.exports = (service) ->
      options = service.options

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive-server2/conf'
      options.log_dir ?= '/var/log/hive-server2'
      options.pid_dir ?= '/var/run/hive-server2'
      # Opts and Java
      options.java_home ?= service.deps.java.options.java_home
      options.opts ?= ''
      options.mode ?= 'local'
      throw Error 'Invalid Options mode: accepted value are "local" or "remote"' unless options.mode in ['local', 'remote']
      options.heapsize ?= if options.mode is 'local' then 1536 else 1024
      # Misc
      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]

## Identities

      options.group = merge {}, service.deps.hive_hcatalog[0].options.group, options.group
      options.user = merge {}, service.deps.hive_hcatalog[0].options.user, options.user

## Configuration

      options.hive_site ?= {}
      properties = [ # Duplicate client, might remove
        'hive.metastore.sasl.enabled'
        'hive.security.authorization.enabled'
        # 'hive.security.authorization.manager'
        'hive.security.metastore.authorization.manager'
        'hive.security.authenticator.manager'
        'hive.optimize.mapjoin.mapreduce'
        'hive.enforce.bucketing'
        'hive.exec.dynamic.partition.mode'
        'hive.txn.manager'
        'hive.txn.timeout'
        'hive.txn.max.open.batch'
        # Transaction, read/write locks
        'hive.support.concurrency'
        'hive.cluster.delegation.token.store.zookeeper.connectString'
        # 'hive.cluster.delegation.token.store.zookeeper.znode'
        'hive.heapsize'
        'hive.exec.max.created.files'
        'hive.auto.convert.sortmerge.join.noconditionaltask'
        'hive.zookeeper.quorum'
      ]
      if options.mode is 'local'
        properties = properties.concat [
          'datanucleus.autoCreateTables'
          'hive.cluster.delegation.token.store.class'
          'hive.cluster.delegation.token.store.zookeeper.znode'
        ]
        options.hive_site['hive.metastore.uris'] = ' '
        options.hive_site['hive.compactor.initiator.on'] = 'false'
      else
        properties.push 'hive.metastore.uris'
      for property in properties
        options.hive_site[property] ?= service.deps.hive_hcatalog[0].options.hive_site[property]
      # Server2 specific properties
      options.hive_site['hive.server2.thrift.sasl.qop'] ?= 'auth'
      options.hive_site['hive.server2.enable.doAs'] ?= 'true'
      # options.hive_site['hive.server2.enable.impersonation'] ?= 'true' # Mention in CDH5.3 but hs2 logs complains it doesnt exist
      options.hive_site['hive.server2.allow.user.substitution'] ?= 'true'
      options.hive_site['hive.server2.transport.mode'] ?= 'http'
      options.hive_site['hive.server2.thrift.port'] ?= '10001'
      options.hive_site['hive.server2.thrift.http.port'] ?= '10001'
      options.hive_site['hive.server2.thrift.http.path'] ?= 'cliservice'
      # Bug fix: java properties are not interpolated
      # Default is "${system:java.io.tmpdir}/${system:user.name}/operation_logs"
      options.hive_site['hive.server2.logging.operation.log.location'] ?= "/tmp/#{options.user.name}/operation_logs"
      # Tez
      # https://streever.atlassian.net/wiki/pages/viewpage.action?pageId=4390918
      options.hive_site['hive.execution.engine'] ?= if service.deps.tez then 'tez' else 'mr'
      options.hive_site['hive.server2.tez.default.queues'] ?= 'default'
      options.hive_site['hive.server2.tez.sessions.per.default.queue'] ?= '1'
      options.hive_site['hive.server2.tez.initialize.default.sessions'] ?= 'false'
      options.hive_site['hive.exec.post.hooks'] ?= 'org.apache.hadoop.hive.ql.hooks.ATSHook'
      # Permission inheritance
      # https://cwiki.apache.org/confluence/display/Hive/Permission+Inheritance+in+Hive
      # true unless ranger is the authorizer
      options.hive_site['hive.warehouse.subdir.inherit.perms'] ?= unless service.deps.ranger_admin then 'true' else 'false'

## Database

Import database information from the Hive Metastore

      merge options.hive_site, service.deps.hive_metastore.options.hive_site

## Hive Server2 Environment

      options.env ?= {}
      #JMX Config
      options.env["JMX_OPTS"] ?= ''
      if options.env["JMXPORT"]? and options.env["JMX_OPTS"].indexOf('-Dcom.sun.management.jmxremote.rmi.port') is -1
        options.env["$JMXSSL"] ?= false
        options.env["$JMXAUTH"] ?= false
        options.env["JMX_OPTS"] += """
        -Dcom.sun.management.jmxremote \
        -Dcom.sun.management.jmxremote.authenticate=#{options.env["$JMXAUTH"]} \
        -Dcom.sun.management.jmxremote.ssl=#{options.env["$JMXSSL"]} \
        -Dcom.sun.management.jmxremote.port=#{options.env["JMXPORT"]} \
        -Dcom.sun.management.jmxremote.rmi.port=#{options.env["JMXPORT"]} \
        """
      # fix bug where phoenix-server and phoenix-client do not contain same
      # version of class used.
      options.aux_jars_paths ?= {}
      if service.deps.hbase_client
        options.aux_jars_paths['/usr/hdp/current/hbase-client/lib/hbase-server.jar'] ?= true
        options.aux_jars_paths['/usr/hdp/current/hbase-client/lib/hbase-client.jar'] ?= true
        options.aux_jars_paths['/usr/hdp/current/hbase-client/lib/hbase-common.jar'] ?= true
      if service.deps.phoenix_client
        options.aux_jars_paths['/usr/hdp/current/phoenix-client/phoenix-hive.jar'] ?= true
      for path, val of service.deps.hive_hcatalog[0].options.aux_jars_paths
        options.aux_jars_paths[path] ?= val
      #aux_jars forced by ryba to guaranty consistency
      options.aux_jars = "#{Object.keys(options.aux_jars_paths).join ':'}"

## Kerberos

      # https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2
      # Authentication type
      options.hive_site['hive.server2.authentication'] ?= 'KERBEROS'
      # The keytab for the HiveServer2 service principal
      # 'options.authentication.kerberos.keytab': "/etc/security/keytabs/hcat.service.keytab"
      options.hive_site['hive.server2.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/hive.service.keytab'
      # The service principal for the HiveServer2. If _HOST
      # is used as the hostname portion, it will be replaced.
      # with the actual hostname of the running instance.
      options.hive_site['hive.server2.authentication.kerberos.principal'] ?= "hive/_HOST@#{options.krb5.realm}"
      # SPNEGO
      options.hive_site['hive.server2.authentication.spnego.principal'] ?= service.deps.hadoop_core.options.core_site['hadoop.http.authentication.kerberos.principal']
      options.hive_site['hive.server2.authentication.spnego.keytab'] ?= service.deps.hadoop_core.options.core_site['hadoop.http.authentication.kerberos.keytab']
      # Ensure we dont create the same principal as with the Hive HCatalog or the kvno will be incremented
      hive_hcatalog_local_srv = service.deps.hive_hcatalog.filter((srv) -> srv.node.id is service.node.id)[0]
      options.principal_identical_to_hcatalog = hive_hcatalog_local_srv and hive_hcatalog_local_srv.options.hive_site['hive.metastore.kerberos.principal'] is options.hive_site['hive.server2.authentication.kerberos.principal']


## SSL

      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl
      options.hive_site['hive.server2.use.SSL'] ?= 'true'
      options.hive_site['hive.server2.keystore.path'] ?= "#{options.conf_dir}/keystore"
      options.hive_site['hive.server2.keystore.password'] ?= service.deps.hadoop_core.options.ssl.keystore.password

## HS2 High Availability & Rolling Upgrade

HS2 use Zookeepper to track registered servers. The znode address is
"/<hs2_namespace>/serverUri=<host:port>;version=<versionInfo>; sequence=<sequence_number>"
and its value is the server "host:port".

      zookeeper_quorum = for srv in service.deps.zookeeper_server
        continue unless srv.options.config['peerType'] is 'participant'
        "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"
      options.hive_site['hive.zookeeper.quorum'] ?= zookeeper_quorum.join ','
      options.hive_site['hive.server2.support.dynamic.service.discovery'] ?= if service.deps.hive_server2.length > 1 then 'true' else 'false'
      options.hive_site['hive.zookeeper.session.timeout'] ?= '600000' # Default is "600000"
      options.hive_site['hive.server2.zookeeper.namespace'] ?= 'hiveserver2' # Default is "hiveserver2"

## Configuration for Proxy users

      for srv in service.deps.hdfs_client
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= '*'

# Configure Log4J

      options.log4j = merge {}, service.deps.log4j?.options, options.log4j
      options.log4j.properties ?= {}
      options.log4j.properties['hive.log.file'] ?= 'hiveserver2.log'
      options.log4j.properties['hive.log.dir'] ?= "#{options.log_dir}"
      options.log4j.properties['log4j.appender.EventCounter'] ?= 'org.apache.hadoop.hive.shims.HiveEventCounter'
      options.log4j.properties['log4j.appender.console'] ?= 'org.apache.log4j.ConsoleAppender'
      options.log4j.properties['log4j.appender.console.target'] ?= 'System.err'
      options.log4j.properties['log4j.appender.console.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j.properties['log4j.appender.console.layout.ConversionPattern'] ?= '%d{yy/MM/dd HH:mm:ss} %p %c{2}: %m%n'
      options.log4j.properties['log4j.appender.console.encoding'] ?= 'UTF-8'
      options.log4j.properties['log4j.appender.RFAS'] ?= 'org.apache.log4j.RollingFileAppender'
      options.log4j.properties['log4j.appender.RFAS.File'] ?= '${hive.log.dir}/${hive.log.file}'
      options.log4j.properties['log4j.appender.RFAS.MaxFileSize'] ?= '20MB'
      options.log4j.properties['log4j.appender.RFAS.MaxBackupIndex'] ?= '10'
      options.log4j.properties['log4j.appender.RFAS.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j.properties['log4j.appender.RFAS.layout.ConversionPattern'] ?= '%d{ISO8601} %-5p %c{2} - %m%n'
      options.log4j.properties['log4j.appender.DRFA'] ?= 'org.apache.log4j.DailyRollingFileAppender'
      options.log4j.properties['log4j.appender.DRFA.File'] ?= '${hive.log.dir}/${hive.log.file}'
      options.log4j.properties['log4j.appender.DRFA.DatePattern'] ?= '.yyyy-MM-dd'
      options.log4j.properties['log4j.appender.DRFA.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j.properties['log4j.appender.DRFA.layout.ConversionPattern'] ?= '%d{ISO8601} %-5p %c{2} (%F:%M(%L)) - %m%n'
      options.log4j.properties['log4j.appender.DAILY'] ?= 'org.apache.log4j.rolling.RollingFileAppender'
      options.log4j.properties['log4j.appender.DAILY.rollingPolicy'] ?= 'org.apache.log4j.rolling.TimeBasedRollingPolicy'
      options.log4j.properties['log4j.appender.DAILY.rollingPolicy.ActiveFileName'] ?= '${hive.log.dir}/${hive.log.file}'
      options.log4j.properties['log4j.appender.DAILY.rollingPolicy.FileNamePattern'] ?= '${hive.log.dir}/${hive.log.file}.%d{yyyy-MM-dd}'
      options.log4j.properties['log4j.appender.DAILY.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j.properties['log4j.appender.DAILY.layout.ConversionPattern'] ?= '%d{dd MMM yyyy HH:mm:ss,SSS} %-5p [%t] (%C.%M:%L) %x - %m%n'
      options.log4j.properties['log4j.appender.AUDIT'] ?= 'org.apache.log4j.RollingFileAppender'
      options.log4j.properties['log4j.appender.AUDIT.File'] ?= '${hive.log.dir}/hiveserver2_audit.log'
      options.log4j.properties['log4j.appender.AUDIT.MaxFileSize'] ?= '20MB'
      options.log4j.properties['log4j.appender.AUDIT.MaxBackupIndex'] ?= '10'
      options.log4j.properties['log4j.appender.AUDIT.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j.properties['log4j.appender.AUDIT.layout.ConversionPattern'] ?= '%d{ISO8601} %-5p %c{2} (%F:%M(%L)) - %m%n'

      options.log4j.appenders = ',RFAS'
      options.log4j.audit_appenders = ',AUDIT'
      if options.log4j.remote_host and options.log4j.remote_port
        options.log4j.appenders = options.log4j.appenders + ',SOCKET'
        options.log4j.audit_appenders = options.log4j.audit_appenders + ',SOCKET'
        options.log4j.properties['log4j.appender.SOCKET'] ?= 'org.apache.log4j.net.SocketAppender'
        options.log4j.properties['log4j.appender.SOCKET.Application'] ?= 'hiveserver2'
        options.log4j.properties['log4j.appender.SOCKET.RemoteHost'] ?= options.log4j.remote_host
        options.log4j.properties['log4j.appender.SOCKET.Port'] ?= options.log4j.remote_port

      options.log4j.properties['log4j.category.DataNucleus'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.category.Datastore'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.category.Datastore.Schema'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.category.JPOX.Datastore'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.category.JPOX.Plugin'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.category.JPOX.MetaData'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.category.JPOX.Query'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.category.JPOX.General'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.category.JPOX.Enhancer'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.hadoop.conf.Configuration'] ?= 'ERROR' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.zookeeper'] ?= 'INFO' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.zookeeper.server.ServerCnxn'] ?= 'WARN' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.zookeeper.server.NIOServerCnxn'] ?= 'WARN' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.zookeeper.ClientCnxn'] ?= 'WARN' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.zookeeper.ClientCnxnSocket'] ?= 'WARN' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.zookeeper.ClientCnxnSocketNIO'] ?= 'WARN' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.hadoop.hive.ql.log.PerfLogger'] ?= '${hive.ql.log.PerfLogger.level}'
      options.log4j.properties['log4j.logger.org.apache.hadoop.hive.ql.exec.Operator'] ?= 'INFO' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.hadoop.hive.serde2.lazy'] ?= 'INFO' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.hadoop.hive.metastore.ObjectStore'] ?= 'INFO' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.hadoop.hive.metastore.MetaStore'] ?= 'INFO' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.hadoop.hive.metastore.HiveMetaStore'] ?= 'INFO' + options.log4j.appenders
      options.log4j.properties['log4j.logger.org.apache.hadoop.hive.metastore.HiveMetaStore.audit'] ?= 'INFO' + options.log4j.audit_appenders
      options.log4j.properties['log4j.additivity.org.apache.hadoop.hive.metastore.HiveMetaStore.audit'] ?= false
      options.log4j.properties['log4j.logger.server.AsyncHttpConnection'] ?= 'OFF'
      options.log4j.properties['hive.log.threshold'] ?= 'ALL'
      options.log4j.properties['hive.root.logger'] ?= 'INFO' + options.log4j.appenders
      options.log4j.properties['log4j.rootLogger'] ?= '${hive.root.logger}, EventCounter'
      options.log4j.properties['log4j.threshold'] ?= '${hive.log.threshold}'

# Hive On HBase

Add Hive user as proxyuser

      for srv in service.deps.hbase_thrift
        # migration: wdavidw 170906, in a future version, we could give access 
        # to parent sevices, eg: srv.use.hadoop_core.options.core_site
        hsrv = service.deps.hdfs_client.filter((hsrv) -> hsrv.node.fqdn is srv.node.fqdn)[0]
        hsrv.options.core_site ?= {}
        hsrv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= '*'
        hsrv.options.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'

## Wait

      options.wait_krb5_client ?= service.deps.krb5_client.options.wait
      options.wait_zookeeper_server ?= service.deps.zookeeper_server[0].options.wait
      options.wait_hive_hcatalog ?= service.deps.hive_hcatalog[0].options.wait
      options.wait = {}
      options.wait.thrift = for srv in service.deps.hive_server2
        srv.options.hive_site ?= {}
        srv.options.hive_site['hive.server2.transport.mode'] ?= 'http'
        srv.options.hive_site['hive.server2.thrift.http.port'] ?= '10001'
        srv.options.hive_site['hive.server2.thrift.port'] ?= '10001'
        host: srv.node.fqdn
        port: if srv.options.hive_site['hive.server2.transport.mode'] is 'http'
        then srv.options.hive_site['hive.server2.thrift.http.port']
        else srv.options.hive_site['hive.server2.thrift.port']

## Dependencies

    {merge} = require 'nikita/lib/misc'
