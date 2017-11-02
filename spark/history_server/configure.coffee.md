
# Spark History Server Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/spark/client', ['ryba', 'spark', 'client'], require('nikita/lib/misc').merge require('.').use,
        ssl: key: ['ssl']
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hdfs_client:  key: ['ryba', 'hdfs_client']
        hadoop_core:  key: ['ryba']
        spark_client: key: ['ryba', 'spark', 'client']
        spark_history: key: ['ryba', 'spark', 'history_server']
      @config.ryba ?= {}
      @config.ryba.spark ?= {}
      options = @config.ryba.spark.history_server = service.options

## Configuration

      options ?= {}
      # Layout
      options.pid_dir ?= '/var/run/spark'
      options.conf_dir ?= '/etc/spark-history-server/conf'
      options.log_dir ?= '/var/log/spark'
      # spark-config
      options.heapsize ?= '2g'
      options.iptables = !!service.use.iptables and service.use.iptables.options.action is 'start'

## Identities

      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'spark'
      options.user.system ?= true
      options.user.comment ?= 'Spark User'
      options.user.home ?= '/var/lib/spark'
      options.user.groups ?= 'hadoop'
      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'spark'
      options.group.system ?= true
      options.user.gid ?= options.group.name

## JAVA Home

      options.java_home ?= service.use.java.options.java_home

### Spark Defaults

Inherits some of the basic spark yarn-cluster based installation

      options.conf ?= {}
      options.conf['options.provider'] ?= 'org.apache.spark.deploy.history.FsHistoryProvider'
      options.conf['options.fs.update.interval'] ?= '10s'
      options.conf['options.retainedApplications'] ?= '50'
      options.conf['options.ui.port'] ?= '18080'

      options.conf['options.kerberos.keytab'] ?= '/etc/security/keytabs/spark.keytab'
      options.conf['options.ui.acls.enable'] ?= 'true'
      options.conf['options.fs.cleaner.enabled'] ?= 'false'
      options.conf['options.retainedApplications'] ?= '50'

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]
      options.conf['spark.yarn.historyServer.address'] ?= "#{service.node.fqdn}:#{options.conf['options.ui.port']}"
      options.conf['options.kerberos.enabled'] ?= if service.use.hadoop_core.options.core_site['hadoop.http.authentication.type'] is 'kerberos' then 'true' else 'false'
      options.conf['options.kerberos.principal'] ?= "spark/#{service.node.fqdn}@#{options.krb5.realm}"

## Inheritance

      for prop in [
        'spark.master'
        'spark.authenticate'
        'spark.authenticate.secret'
        'spark.eventLog.enabled'
        'spark.eventLog.dir'
        'options.fs.logDirectory'
        'spark.yarn.services'
        'spark.ssl.enabledAlgorithms'
        'spark.eventLog.overwrite'
        'spark.yarn.jar'
        'options.retainedApplications'
        'spark.yarn.applicationMaster.waitTries'
        'spark.yarn.am.waitTime'
        'spark.yarn.containerLauncherMaxThreads'
        'spark.yarn.driver.memoryOverhead'
        'spark.yarn.executor.memoryOverhead'
        'spark.yarn.max.executor.failures'
        'spark.yarn.preserve.staging.files'
        'spark.yarn.queue'
        'spark.yarn.scheduler.heartbeat.interval-ms'
        'spark.yarn.submit.file.replication'
      ] then options.conf[prop] ?= service.use.spark_client[0].options.conf[prop]



### Configure client

      for srv in service.use.spark_client
        srv.options.conf['options.provider'] = options.conf['options.provider']
        srv.options.conf['options.ui.port'] = options.conf['options.ui.port']
        srv.options.conf['spark.yarn.historyServer.address'] = options.conf['spark.yarn.historyServer.address']

### Log4j Properties

      options.log4j ?= {}
      options.log4j['log4j.rootCategory'] ?= 'INFO, console'
      options.log4j['log4j.appender.console'] ?= 'org.apache.log4j.ConsoleAppender'
      options.log4j['log4j.appender.console.target'] ?= 'System.out'
      options.log4j['log4j.appender.console.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j['log4j.appender.console.layout.ConversionPattern'] ?= '%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n'


      # Settings to quiet third party logs that are too verbose
      options.log4j['log4j.logger.org.spark-project.jetty'] ?= 'WARN'
      options.log4j['log4j.logger.org.spark-project.jetty.util.component.AbstractLifeCycle'] ?= 'ERROR'
      options.log4j['log4j.logger.org.apache.spark.repl.SparkIMain$exprTyper'] ?= 'INFO'
      options.log4j['log4j.logger.org.apache.spark.repl.SparkILoop$SparkILoopInterpreter'] ?= 'INFO'
      options.log4j['log4j.logger.org.apache.parquet'] ?= 'ERROR'
      options.log4j['log4j.logger.parquet'] ?= 'ERROR'

      # SPARK-9183: Settings to avoid annoying messages when looking up nonexistent UDFs in SparkSQL with Hive support
      options.log4j['log4j.logger.org.apache.hadoop.hive.metastore.RetryingHMSHandler'] ?= 'FATAL'
      options.log4j['log4j.logger.org.apache.hadoop.hive.ql.exec.FunctionRegistry'] ?= 'ERROR'

### SSL

      options.conf['spark.ssl.enabled'] ?= 'true'
      options.conf['spark.ssl.protocol'] ?= 'SSLv3'
      options.conf['spark.ssl.trustStore'] ?= service.use.hadoop_core.options.ssl_client['ssl.client.truststore.location']
      options.conf['spark.ssl.trustStorePassword'] ?= service.use.hadoop_core.options.ssl_client['ssl.client.truststore.password']

### Kerberos

Spark History Server server is runned as the spark user

      options.conf['options.kerberos.enabled'] ?= if service.use.hadoop_core.options.core_site['hadoop.http.authentication.type'] is 'kerberos' then 'true' else 'false'
      options.conf['options.kerberos.principal'] ?= "spark/#{service.node.fqdn}@#{options.krb5.realm}"
      options.conf['options.kerberos.keytab'] ?= '/etc/security/keytabs/spark.service.keytab'

## Wait

      options.wait ?= {}
      options.wait.ui = for srv in service.use.spark_history
        host: srv.node.fqdn
        port: srv.options?.conf?['spark.history.ui.port'] or options.conf['spark.history.ui.port'] or '18080'

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
