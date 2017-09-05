
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

    module.exports = ->
      zoo_ctxs = @contexts('ryba/zookeeper/server').filter( (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant')
      hadoop_ctxs = @contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      hcat_ctxs = @contexts 'ryba/hive/hcatalog'
      hs2_ctxs = @contexts 'ryba/hive/server2'
      hm_ctxs = @contexts 'ryba/hbase/master'
      hbase_client = @contexts 'ryba/hbase/client'
      hthrift_ctxs = @contexts 'ryba/hbase/thrift'
      phoenix_ctxs = @contexts 'ryba/phoenix/client'
      ranger_ctxs = @contexts 'ryba/ranger/admin'
      {core_site, hive, realm} = @config.ryba ?= {}
      {java_home} = @config.java
      options = @config.ryba.hive.server2 ?= {}

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive-server2/conf'
      options.log_dir ?= '/var/log/hive-server2'
      options.pid_dir ?= '/var/run/hive-server2'
      # Opts and Java
      options.opts ?= ''
      options.mode ?= 'local'
      throw Error 'Invalid Options mode: accepted value are "local" or "remote"' unless options.mode in ['local', 'remote']
      options.heapsize ?= if options.mode is 'local' then 1536 else 1024

## Identities

      options.group = merge hcat_ctxs[0].config.ryba.hive.hcatalog.group, options.group
      options.user = merge hcat_ctxs[0].config.ryba.hive.hcatalog.user, options.user

## Configuration

      options.site ?= {}
      options.site[k] ?= v for k, v of hive.metastore.site
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
        options.site['hive.metastore.uris'] = ' '
        options.site['hive.compactor.initiator.on'] = 'false'
      else
        properties.push 'hive.metastore.uris'
      for property in properties
        options.site[property] ?= hcat_ctxs[0].config.ryba.hive.hcatalog.site[property]
      # Server2 specific properties
      options.site['hive.server2.thrift.sasl.qop'] ?= 'auth'
      options.site['hive.server2.enable.doAs'] ?= 'true'
      # options.site['hive.server2.enable.impersonation'] ?= 'true' # Mention in CDH5.3 but hs2 logs complains it doesnt exist
      options.site['hive.server2.allow.user.substitution'] ?= 'true'
      options.site['hive.server2.transport.mode'] ?= 'http'
      options.site['hive.server2.thrift.port'] ?= '10001'
      options.site['hive.server2.thrift.http.port'] ?= '10001'
      options.site['hive.server2.thrift.http.path'] ?= 'cliservice'
      # Bug fix: java properties are not interpolated
      # Default is "${system:java.io.tmpdir}/${system:user.name}/operation_logs"
      options.site['hive.server2.logging.operation.log.location'] ?= "/tmp/#{options.user.name}/operation_logs"
      # Tez
      # https://streever.atlassian.net/wiki/pages/viewpage.action?pageId=4390918
      options.site['hive.execution.engine'] ?= 'tez'
      options.site['hive.server2.tez.default.queues'] ?= 'default'
      options.site['hive.server2.tez.sessions.per.default.queue'] ?= '1'
      options.site['hive.server2.tez.initialize.default.sessions'] ?= 'false'
      options.site['hive.exec.post.hooks'] ?= 'org.apache.hadoop.hive.ql.hooks.ATSHook'
      # Permission inheritance
      # https://cwiki.apache.org/confluence/display/Hive/Permission+Inheritance+in+Hive
      # true unless ranger is the authorizer
      options.site['hive.warehouse.subdir.inherit.perms'] ?= "#{ranger_ctxs.length is 0}"

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
      aux_jars = hcat_ctxs[0].config.ryba.hive.hcatalog.aux_jars
      # fix bug where phoenix-server and phoenix-client do not contain same
      # version of class used.
      paths = []
      if hm_ctxs.length and @has_service 'ryba/hbase/client'
        paths.push '/usr/hdp/current/hbase-client/lib/hbase-server.jar'
        paths.push '/usr/hdp/current/hbase-client/lib/hbase-client.jar'
        paths.push '/usr/hdp/current/hbase-client/lib/hbase-common.jar'
        if @has_service 'ryba/phoenix/client'
          #aux_jars.push '/usr/hdp/current/phoenix-client/phoenix-server.jar'
          paths.push '/usr/hdp/current/phoenix-client/phoenix-hive.jar'
      options.aux_jars_paths ?= []
      options.aux_jars_paths.push p if options.aux_jars_paths.indexOf(p) is -1 for p in paths
      options.aux_jars ?= "#{options.aux_jars_paths.join ':'}"

## Configure Kerberos

      # https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2
      # Authentication type
      options.site['hive.server2.authentication'] ?= 'KERBEROS'
      # The keytab for the HiveServer2 service principal
      # 'options.authentication.kerberos.keytab': "/etc/security/keytabs/hcat.service.keytab"
      options.site['hive.server2.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/hive.service.keytab'
      # The service principal for the HiveServer2. If _HOST
      # is used as the hostname portion, it will be replaced.
      # with the actual hostname of the running instance.
      options.site['hive.server2.authentication.kerberos.principal'] ?= "hive/_HOST@#{realm}"
      # SPNEGO
      options.site['hive.server2.authentication.spnego.principal'] ?= core_site['hadoop.http.authentication.kerberos.principal']
      options.site['hive.server2.authentication.spnego.keytab'] ?= core_site['hadoop.http.authentication.kerberos.keytab']

## Configure SSL

      options.site['hive.server2.use.SSL'] ?= 'true'
      options.site['hive.server2.keystore.path'] ?= "#{options.conf_dir}/keystore"
      options.site['hive.server2.keystore.password'] ?= "ryba123"
      options.truststore_location ?= "#{options.conf_dir}/truststore"
      options.truststore_password ?= "ryba123"

## HS2 High Availability & Rolling Upgrade

HS2 use Zookeepper to track registered servers. The znode address is
"/<hs2_namespace>/serverUri=<host:port>;version=<versionInfo>; sequence=<sequence_number>"
and its value is the server "host:port".

      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      options.site['hive.zookeeper.quorum'] ?= zookeeper_quorum.join ','
      options.site['hive.server2.support.dynamic.service.discovery'] ?= if hs2_ctxs.length > 1 then 'true' else 'false'
      options.site['hive.zookeeper.session.timeout'] ?= '600000' # Default is "600000"
      options.site['hive.server2.zookeeper.namespace'] ?= 'hiveserver2' # Default is "hiveserver2"

## Configuration for Proxy users

      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= '*'

# Configure Log4J

      options.log4j ?= {}
      options.log4j[k] ?= v for k, v of @config.log4j
      config = options.log4j.config ?= {}
      config['hive.log.file'] ?= 'hiveserver2.log'
      config['hive.log.dir'] ?= "#{options.log_dir}"
      config['log4j.appender.EventCounter'] ?= 'org.apache.hadoop.hive.shims.HiveEventCounter'
      config['log4j.appender.console'] ?= 'org.apache.log4j.ConsoleAppender'
      config['log4j.appender.console.target'] ?= 'System.err'
      config['log4j.appender.console.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.console.layout.ConversionPattern'] ?= '%d{yy/MM/dd HH:mm:ss} %p %c{2}: %m%n'
      config['log4j.appender.console.encoding'] ?= 'UTF-8'
      config['log4j.appender.RFAS'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.RFAS.File'] ?= '${hive.log.dir}/${hive.log.file}'
      config['log4j.appender.RFAS.MaxFileSize'] ?= '20MB'
      config['log4j.appender.RFAS.MaxBackupIndex'] ?= '10'
      config['log4j.appender.RFAS.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.RFAS.layout.ConversionPattern'] ?= '%d{ISO8601} %-5p %c{2} - %m%n'
      config['log4j.appender.DRFA'] ?= 'org.apache.log4j.DailyRollingFileAppender'
      config['log4j.appender.DRFA.File'] ?= '${hive.log.dir}/${hive.log.file}'
      config['log4j.appender.DRFA.DatePattern'] ?= '.yyyy-MM-dd'
      config['log4j.appender.DRFA.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.DRFA.layout.ConversionPattern'] ?= '%d{ISO8601} %-5p %c{2} (%F:%M(%L)) - %m%n'
      config['log4j.appender.DAILY'] ?= 'org.apache.log4j.rolling.RollingFileAppender'
      config['log4j.appender.DAILY.rollingPolicy'] ?= 'org.apache.log4j.rolling.TimeBasedRollingPolicy'
      config['log4j.appender.DAILY.rollingPolicy.ActiveFileName'] ?= '${hive.log.dir}/${hive.log.file}'
      config['log4j.appender.DAILY.rollingPolicy.FileNamePattern'] ?= '${hive.log.dir}/${hive.log.file}.%d{yyyy-MM-dd}'
      config['log4j.appender.DAILY.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.DAILY.layout.ConversionPattern'] ?= '%d{dd MMM yyyy HH:mm:ss,SSS} %-5p [%t] (%C.%M:%L) %x - %m%n'
      config['log4j.appender.AUDIT'] ?= 'org.apache.log4j.RollingFileAppender'
      config['log4j.appender.AUDIT.File'] ?= '${hive.log.dir}/hiveserver2_audit.log'
      config['log4j.appender.AUDIT.MaxFileSize'] ?= '20MB'
      config['log4j.appender.AUDIT.MaxBackupIndex'] ?= '10'
      config['log4j.appender.AUDIT.layout'] ?= 'org.apache.log4j.PatternLayout'
      config['log4j.appender.AUDIT.layout.ConversionPattern'] ?= '%d{ISO8601} %-5p %c{2} (%F:%M(%L)) - %m%n'

      options.log4j.appenders = ',RFAS'
      options.log4j.audit_appenders = ',AUDIT'
      if options.log4j.remote_host and options.log4j.remote_port
        options.log4j.appenders = options.log4j.appenders + ',SOCKET'
        options.log4j.audit_appenders = options.log4j.audit_appenders + ',SOCKET'
        config['log4j.appender.SOCKET'] ?= 'org.apache.log4j.net.SocketAppender'
        config['log4j.appender.SOCKET.Application'] ?= 'hiveserver2'
        config['log4j.appender.SOCKET.RemoteHost'] ?= options.log4j.remote_host
        config['log4j.appender.SOCKET.Port'] ?= options.log4j.remote_port

      config['log4j.category.DataNucleus'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.category.Datastore'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.category.Datastore.Schema'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.category.JPOX.Datastore'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.category.JPOX.Plugin'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.category.JPOX.MetaData'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.category.JPOX.Query'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.category.JPOX.General'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.category.JPOX.Enhancer'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.logger.org.apache.hadoop.conf.Configuration'] ?= 'ERROR' + options.log4j.appenders
      config['log4j.logger.org.apache.zookeeper'] ?= 'INFO' + options.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.server.ServerCnxn'] ?= 'WARN' + options.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.server.NIOServerCnxn'] ?= 'WARN' + options.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.ClientCnxn'] ?= 'WARN' + options.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.ClientCnxnSocket'] ?= 'WARN' + options.log4j.appenders
      config['log4j.logger.org.apache.zookeeper.ClientCnxnSocketNIO'] ?= 'WARN' + options.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.ql.log.PerfLogger'] ?= '${hive.ql.log.PerfLogger.level}'
      config['log4j.logger.org.apache.hadoop.hive.ql.exec.Operator'] ?= 'INFO' + options.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.serde2.lazy'] ?= 'INFO' + options.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.metastore.ObjectStore'] ?= 'INFO' + options.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.metastore.MetaStore'] ?= 'INFO' + options.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.metastore.HiveMetaStore'] ?= 'INFO' + options.log4j.appenders
      config['log4j.logger.org.apache.hadoop.hive.metastore.HiveMetaStore.audit'] ?= 'INFO' + options.log4j.audit_appenders
      config['log4j.additivity.org.apache.hadoop.hive.metastore.HiveMetaStore.audit'] ?= false
      config['log4j.logger.server.AsyncHttpConnection'] ?= 'OFF'
      config['hive.log.threshold'] ?= 'ALL'
      config['hive.root.logger'] ?= 'INFO' + options.log4j.appenders
      config['log4j.rootLogger'] ?= '${hive.root.logger}, EventCounter'
      config['log4j.threshold'] ?= '${hive.log.threshold}'

# Hive On HBase

Add Hive user as proxyuser

      for hthrift_ctx in hthrift_ctxs
        hthrift_ctx.config.ryba.core_site ?= {}
        hthrift_ctx.config.ryba.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= '*'
        hthrift_ctx.config.ryba.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
