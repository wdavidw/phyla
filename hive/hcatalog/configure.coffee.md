
# Hive HCatalog Configure

[HCatalog](https://cwiki.apache.org/confluence/display/Hive/HCatalog+UsingHCat) 
is a table and storage management layer for Hadoop that enables users with different 
data processing tools — Pig, MapReduce — to more easily read and write data on the grid.
 HCatalog’s table abstraction presents users with a relational view of data in the Hadoop
 distributed file system (HDFS) and ensures that users need not worry about where or in what
 format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

## Configure

Example:

```json
{
  "ryba": {
    "hive": {
      "hcatalog": {
        "opts": "-Xmx4096m",
        "heapsize": "1024"
      },
      "site": {
        "hive.server2.transport.mode": "http"
      }
    }
  }
}
```

    module.exports = (service) ->
      options = service.options

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive-hcatalog/conf'
      options.log_dir ?= '/var/log/hive-hcatalog'
      options.pid_dir ?= '/var/run/hive-hcatalog'
      options.hdfs_conf_dir ?= service.deps.hdfs_client.options.conf_dir
      # Opts and Java
      options.java_home ?= service.deps.java.options.java_home
      options.opts ?= ''
      options.heapsize ?= 1024
      options.libs ?= []
      # Misc
      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.clean_logs ?= false
      options.tez_enabled ?= service.deps.tez
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      # HDFS
      options.hdfs_conf_dir ?= service.deps.hadoop_core.options.conf_dir

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # HDFS Kerberos Admin
      options.hdfs_krb5_user ?= service.deps.hadoop_core.options.hdfs.krb5_user
      options.nn_url ?= service.deps.hdfs_client.options.nn_url

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'hive'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'hive'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.groups ?= 'hadoop'
      options.user.comment ?= 'Hive User'
      options.user.home ?= '/var/lib/hive'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= true

## Configuration Env

      options.env ?=  {}
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
      options.aux_jars_paths ?= {}
      options.aux_jars_paths['/usr/hdp/current/hive-webhcat/share/hcatalog/hive-hcatalog-core.jar'] ?= true
      #aux_jars forced by ryba to guaranty consistency
      options.aux_jars = "#{Object.keys(options.aux_jars_paths).join ':'}"

## Warehouse directory

      options.warehouse_mode ?= null # let ranger overwrite to '0000' or use '1777'

## Configuration

      options.hive_site ?= {}
      # by default BONECP could lead to BLOCKED thread for class reading from DB
      options.hive_site['datanucleus.connectionPoolingType'] ?= 'DBCP'
      options.hive_site['hive.metastore.port'] ?= '9083'
      options.hive_site['hive.hwi.listen.port'] ?= '9999'
      options.hive_site['hive.metastore.uris'] ?= (
        for srv in service.deps.hive_hcatalog
          srv.options.hive_site ?= {}
          srv.options.hive_site['hive.metastore.port'] ?= 9083
          "thrift://#{srv.node.fqdn}:#{srv.options.hive_site['hive.metastore.port'] or '9083'}"
      ).join ','
      options.hive_site['datanucleus.autoCreateTables'] ?= 'true'
      options.hive_site['hive.security.authorization.enabled'] ?= 'true'
      options.hive_site['hive.security.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      options.hive_site['hive.security.metastore.authorization.manager'] ?= 'org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider'
      options.hive_site['hive.security.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.ProxyUserAuthenticator'
      # see https://cwiki.apache.org/confluence/display/Hive/WebHCat+InstallWebHCat
      options.hive_site['hive.security.metastore.authenticator.manager'] ?= 'org.apache.hadoop.hive.ql.security.HadoopDefaultMetastoreAuthenticator'
      options.hive_site['hive.metastore.pre.event.listeners'] ?= 'org.apache.hadoop.hive.ql.security.authorization.AuthorizationPreEventListener'
      options.hive_site['hive.metastore.cache.pinobjtypes'] ?= 'Table,Database,Type,FieldSchema,Order'

# HDFS Layout

Hive 0.14.0 and later:  HDFS root scratch directory for Hive jobs, which gets 
created with write all (733) permission. For each connecting user, an HDFS 
scratch directory ${hive.exec.scratchdir}/<username> is created with 
${hive.scratch.dir.permission}.

      options.hive_site['hive.metastore.warehouse.dir'] ?= "/apps/#{options.user.name}/warehouse"
      options.hive_site['hive.exec.scratchdir'] ?= "/tmp/hive"
      ## Hive 3
      options.hive_site['hive.create.as.insert.only'] ?= 'true'
      options.hive_site['metastore.create.as.acid'] ?= 'true'
      options.hive_site['hive.metastore.warehouse.external.dir'] ?= '/warehouse/tablespace/external/hive'#location of default database for the warehouse of external tables
      options.hive_site['hive.hook.proto.base-directory'] ?= "#{options.hive_site['hive.metastore.warehouse.external.dir']}/sys.db/query_data"

## Common Configuration

      # To prevent memory leak in unsecure mode, disable [file system caches](https://cwiki.apache.org/confluence/display/Hive/Setting+up+HiveServer2)
      # , by setting following params to true
      options.hive_site['fs.hdfs.impl.disable.cache'] ?= 'false'
      options.hive_site['fs.file.impl.disable.cache'] ?= 'false'
      # TODO: encryption is only with Kerberos, need to check first
      # http://hortonworks.com/blog/encrypting-communication-between-hadoop-and-your-analytics-tools/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+hortonworks%2Ffeed+%28Hortonworks+on+Hadoop%29
      options.hive_site['hive.server2.thrift.sasl.qop'] ?= 'auth'
      # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm-chap14-2-3.html#rmp-chap14-2-3-5
      # If true, the metastore thrift interface will be secured with
      # SASL. Clients must authenticate with Kerberos.
      # Unset unvalid properties
      options.hive_site['hive.optimize.mapjoin.mapreduce'] ?= null
      options.hive_site['hive.heapsize'] ?= null
      options.hive_site['hive.auto.convert.sortmerge.join.noconditionaltask'] ?= null # "does not exist"
      options.hive_site['hive.exec.max.created.files'] ?= '100000' # "expects LONG type value"

## Kerberos

      options.hive_site['hive.metastore.sasl.enabled'] ?= 'true'
      # The path to the Kerberos Keytab file containing the metastore
      # thrift server's service principal.
      options.hive_site['hive.metastore.kerberos.keytab.file'] ?= '/etc/security/keytabs/hive.service.keytab'
      # The service principal for the metastore thrift server. The
      # special string _HOST will be replaced automatically with the correct  hostname.
      options.hive_site['hive.metastore.kerberos.principal'] ?= "hive/_HOST@#{options.krb5.realm}"

## Database

Import database information from the Hive Metastore

      
      options.db = merge {}, service.deps.hive_metastore.options.db, options.db
      merge options.hive_site, service.deps.hive_metastore.options.hive_site

## Configure Transactions and Lock Manager

With the addition of transactions in Hive 0.13 it is now possible to provide
full ACID semantics at the row level, so that one application can add rows while
another reads from the same partition without interfering with each other.

      # Get ZooKeeper Quorum
      zookeeper_quorum = for srv in service.deps.zookeeper_server
        continue unless srv.options.config['peerType'] is 'participant'
        "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"
      # Enable Table Lock Manager
      # Accoring to [Cloudera](http://www.cloudera.com/content/cloudera/en/documentation/cdh4/v4-2-0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html),
      # enabling the Table Lock Manager without specifying a list of valid
      # Zookeeper quorum nodes will result in unpredictable behavior. Make sure
      # that both properties are properly configured.
      options.hive_site['hive.support.concurrency'] ?= 'true' # Required, default to false
      options.hive_site['hive.zookeeper.quorum'] ?= zookeeper_quorum.join ','
      options.hive_site['hive.enforce.bucketing'] ?= 'true' # Required, default to false,  set to true to support INSERT ... VALUES, UPDATE, and DELETE transactions
      options.hive_site['hive.exec.dynamic.partition.mode'] ?= 'nonstrict' # Required, default to strict
      # options.hive_site['hive.txn.manager'] ?= 'org.apache.hadoop.hive.ql.lockmgr.DummyTxnManager'
      options.hive_site['hive.txn.manager'] ?= 'org.apache.hadoop.hive.ql.lockmgr.DbTxnManager'
      options.hive_site['hive.txn.timeout'] ?= '300'
      options.hive_site['hive.txn.max.open.batch'] ?= '1000'

hive.compactor.initiator.on can be activated on only one node !
[hive compactor initiator][initiator]
So we provide true by default on the 1st hive-hcatalog-server, but we force false elsewhere

      if service.deps.hive_hcatalog[0].node.fqdn is service.node.fqdn
        options.hive_site['hive.compactor.initiator.on'] ?= 'true'
      else
        options.hive_site['hive.compactor.initiator.on'] = 'false'
      options.hive_site['hive.compactor.worker.threads'] ?= '1' # Required > 0
      options.hive_site['hive.compactor.worker.timeout'] ?= '86400L'
      options.hive_site['hive.compactor.cleaner.run.interval'] ?= '5000'
      options.hive_site['hive.compactor.check.interval'] ?= '300L'
      options.hive_site['hive.compactor.delta.num.threshold'] ?= '10'
      options.hive_site['hive.compactor.delta.pct.threshold'] ?= '0.1f'
      options.hive_site['hive.compactor.abortedtxn.threshold'] ?= '1000'

## Configure HA

*   [Cloudera "Table Lock Manager" for Server2][ha_cdh5].
*   [Hortonworks Hive HA for HDP2.2][ha_hdp_2.2]
*   [Support dynamic service discovery for HiveServer2][HIVE-7935]

The [new Lock Manager][lock_mgr] introduced in Hive 0.13.0 shall accept
connections from multiple Server2 by introducing [transactions][[trnx].

The [MemoryTokenStore] is used if there is only one HCatalog Server otherwise we
default to the [DBTokenStore]. Also worth of interest is the
[ZooKeeperTokenStore].

      options.hive_site['hive.cluster.delegation.token.store.class'] ?= 'org.apache.hadoop.hive.thrift.ZooKeeperTokenStore'
      # options.hive_site['hive.cluster.delegation.token.store.class'] ?= if hive_hcatalog.length > 1
      # # then 'org.apache.hadoop.hive.thrift.ZooKeeperTokenStore'
      # then 'org.apache.hadoop.hive.thrift.DBTokenStore'
      # else 'org.apache.hadoop.hive.thrift.MemoryTokenStore'
      switch options.hive_site['hive.cluster.delegation.token.store.class']
        when 'org.apache.hadoop.hive.thrift.ZooKeeperTokenStore'
          options.hive_site['hive.cluster.delegation.token.store.zookeeper.connectString'] ?= zookeeper_quorum.join ','
          options.hive_site['hive.cluster.delegation.token.store.zookeeper.znode'] ?= '/hive/cluster/delegation'

## Configure SSL

      # options.truststore_location ?= "#{options.conf_dir}/truststore"
      # options.truststore_password ?= "ryba123"

## Proxy users

      for srv in service.deps.yarn_rm
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= '*'
      # migration: david 170907, dont know why we doing locally since looping
      # through each hdfs_client should do the job
      # #hive-hcatalog server's client core site also need to be set
      # @config.core_site ?= {}
      # @config.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
      # @config.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= '*'

## Log4J

      options.log4j = merge {}, service.deps.log4j?.options, options.log4j
      options.log4j.properties ?= {}
      options.application ?= 'metastore'
      options.log4j.properties['hive.log.file'] ?= 'hcatalog.log'
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
      options.log4j.properties['log4j.appender.AUDIT.File'] ?= '${hive.log.dir}/hcatalog_audit.log'
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
        options.log4j.properties['log4j.appender.SOCKET.Application'] ?= options.application
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

## Wait

      options.wait_krb5_client ?= service.deps.krb5_client.options.wait
      options.wait_zookeeper_server ?= service.deps.zookeeper_server[0].options.wait
      options.wait_hdfs_nn = service.deps.hdfs_nn[0].options.wait
      options.wait_db_admin ?= service.deps.db_admin.options.wait
      options.wait = {}
      options.wait.rpc = for srv in service.deps.hive_hcatalog
        srv.options.hive_site ?= {}
        srv.options.hive_site['hive.metastore.port'] ?= 9083
        host: srv.node.fqdn
        port: srv.options.hive_site['hive.metastore.port']

# Module Dependencies

    {merge} = require '@nikita/core/lib/misc'
    db = require '@nikita/core/lib/misc/db'

[HIVE-7935]: https://issues.apache.org/jira/browse/HIVE-7935
[ha_hdp_2.2]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/Hadoop_HA_v22/ha_hive_metastore/index.html#Item1.1.2
[ha_cdh5]: http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_ha_hivemetastore.html#concept_jqx_zqk_dq_unique_1
[trnx]: https://cwiki.apache.org/confluence/display/Hive/Hive+Transactions#HiveTransactions-LockManager
[lock_mgr]: https://cwiki.apache.org/confluence/display/Hive/Hive+Transactions#HiveTransactions-LockManager
[MemoryTokenStore]: https://github.com/apache/hive/blob/trunk/shims/common/src/main/java/org/apache/hadoop/hive/thrift/MemoryTokenStore.java
[DBTokenStore]: https://github.com/apache/hive/blob/trunk/shims/common/src/main/java/org/apache/hadoop/hive/thrift/DBTokenStore.java
[ZooKeeperTokenStore]: https://github.com/apache/hive/blob/trunk/shims/common/src/main/java/org/apache/hadoop/hive/thrift/ZooKeeperTokenStore.java
[initiator]: https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties#ConfigurationProperties-hive.compactor.initiator.on
[hive-postgresql]: http://docs.hortonworks.com/HDPDocuments/Ambari-2.1.0.0/bk_ambari_reference_guide/content/_using_hive_with_postgresql.html
