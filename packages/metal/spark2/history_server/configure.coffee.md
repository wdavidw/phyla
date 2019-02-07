
# Spark History Server Configure

    module.exports = (service) ->
      options = service.options

## Configuration

      # Layout
      options.pid_dir ?= '/var/run/spark'
      options.conf_dir ?= '/etc/spark-history-server/conf'
      options.log_dir ?= '/var/log/spark'
      # spark-config
      options.heapsize ?= '2g'
      options.iptables = !!service.deps.iptables and service.deps.iptables.options.action is 'start'

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

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Kerberos HDFS Admin
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## JAVA Home

      options.java_home ?= service.deps.java.options.java_home

## Configuration Spark Defaults

Inherits some of the basic spark yarn-cluster based installation

      options.conf ?= {}
      options.conf['spark.history.provider'] ?= 'org.apache.spark.deploy.history.FsHistoryProvider'
      options.conf['spark.history.fs.update.interval'] ?= '10s'
      options.conf['spark.history.retainedApplications'] ?= '50'
      options.conf['spark.history.ui.port'] ?= '18080'

      options.conf['spark.history.kerberos.keytab'] ?= '/etc/security/keytabs/spark.keytab'
      options.conf['spark.history.ui.acls.enable'] ?= 'true'
      options.conf['spark.history.fs.cleaner.enabled'] ?= 'false'
      options.conf['spark.history.retainedApplications'] ?= '50'

## Configuration Kerberos

Spark History Server server is runned as the spark user.

      options.conf['spark.yarn.historyServer.address'] ?= "#{service.node.fqdn}:#{options.conf['spark.history.ui.port']}"
      options.conf['spark.history.kerberos.enabled'] ?= if service.deps.hadoop_core.options.core_site['hadoop.http.authentication.type'] is 'kerberos' then 'true' else 'false'
      options.conf['spark.history.kerberos.principal'] ?= "spark/#{service.node.fqdn}@#{options.krb5.realm}"
      options.conf['spark.history.kerberos.keytab'] ?= '/etc/security/keytabs/spark.service.keytab'

## Configuration UI SSL
Use official [2.X documentation](https://spark.apache.org/docs/latest/security.html#ssl-configuration)
to configure ssl and use hadoop credential configuration to store passwords.

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      options.truststore ?= {}
      options.keystore ?= {}
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        options.truststore.target ?= "#{options.conf_dir}/truststore"
        throw Error "Required Property: truststore.password" if not options.truststore.password
        options.truststore.caname ?= 'hadoop_root_ca'
        options.truststore.type ?= 'jks'
        throw Error "Invalid Truststore Type: #{truststore.type}" unless options.truststore.type in ['jks', 'jceks', 'pkcs12']
        options.keystore.target ?= "#{options.conf_dir}/keystore"
        throw Error "Required Property: keystore.password" if not options.keystore.password
        options.keystore.caname ?= 'hadoop_root_ca'
        options.keystore.type ?= 'jks'
        throw Error "Invalid KeyStore Type: #{keystore.type}" unless options.keystore.type in ['jks', 'jceks', 'pkcs12']
        options.conf['spark.ssl.historyServer.enabled'] ?= 'true'
        options.conf['spark.ssl.historyServer.port'] ?= '18080'
        # options.conf['spark.ssl.historyServer.keyPassword'] ?= options.keystore.password
        options.conf['spark.ssl.historyServer.keyStore'] ?= options.keystore.target
        # options.conf['spark.ssl.historyServer.keyStorePassword'] ?= options.keystore.password
        options.conf['spark.ssl.historyServer.keyStoreType'] ?= options.keystore.type
        options.conf['spark.ssl.historyServer.trustStore'] ?= options.truststore.target
        # options.conf['spark.ssl.historyServer.trustStorePassword'] ?= options.truststore.password
        options.conf['spark.ssl.historyServer.trustStoreType'] ?= options.truststore.type
        options.conf['hadoop.security.credential.provider.path'] ?= "jceks://file#{options.conf_dir}/history-ui-credential.jceks"

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
      ] then options.conf[prop] ?= service.deps.spark_client[0].options.conf[prop]

## Configuration client

      for srv in service.deps.spark_client
        srv.options.conf['spark.history.provider'] = options.conf['spark.history.provider']
        srv.options.conf['spark.history.ui.port'] = options.conf['spark.history.ui.port']
        srv.options.conf['spark.yarn.historyServer.address'] = options.conf['spark.yarn.historyServer.address']

## Log4j Properties

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

## Wait

      options.wait ?= {}
      options.wait.ui = for srv in service.deps.spark_history
        host: srv.node.fqdn
        port: srv.options?.conf?['spark.history.ui.port'] or options.conf['spark.history.ui.port'] or '18080'

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
