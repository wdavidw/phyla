
# Spark Thrift Server

    module.exports = (service) ->
      options = service.options
      throw Error 'Spark SQL Thrift Server must be installed on the same host than hive-server2' unless service.deps.hive_server2.map((srv)-> srv.node.fqdn).indexOf(service.node.fqdn) > -1
      throw Error 'Spark SQL Thrift Server is useless without spark installed' unless service.deps.spark_client?

## Identities

      options.group = merge service.deps.spark_client.options.group, options.group
      options.user = merge service.deps.spark_client.options.user, options.user
      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.hdfs_krb5_user = service.deps.hdfs_nn[0].options.hdfs_krb5_user

## Layout

Spark SQL thrift server starts a custom instance of hive-server2, we use the same properties 
than the hive-server2 (available on the same host). We inherits from almost every properties.
Only port, execution engine and dynamic discovery change (not supported).

## Configuration

      options.user_name ?= service.deps.hive_server2[0].options.user.name
      options.log_dir ?= '/var/log/spark'
      options.pid_dir ?= '/var/run/spark' 
      options.conf_dir ?= '/etc/spark-thrift-server/conf'
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

## Java

      options.java_home ?= service.deps.java.options.java_home

## SSL

      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl

### Hive server2 Configuration

      options.hive_site ?= {}
      options.hive_site['hive.server2.transport.mode'] ?= 'binary'
      options.hive_site['hive.server2.thrift.port'] ?= '10015'
      options.hive_site['hive.server2.thrift.http.port'] ?= '10015'
      options.hive_site['hive.server2.use.SSL'] ?= 'true'
      options.hive_site['hive.server2.keystore.path'] ?= "#{options.conf_dir}/keystore"
      options.hive_site['hive.server2.keystore.password'] ?= 'ryba123'
      options.hive_site['hive.execution.engine'] = 'mr'
      # Do not modify this property, hive server2 spark instance does not support zookeeper dynamic discovery
      options.hive_site['hive.server2.support.dynamic.service.discovery'] = 'false' 

### Spark Defaults

Inherits some of the basic spark yarn-cluster based installation

      options.conf ?= {}
      options.conf['spark.master'] ?= 'yarn-client'
      options.conf['spark.executor.memory'] ?= '512m'
      options.conf['spark.driver.memory'] ?= '512m'

      for prop in [
        'spark.authenticate'
        'spark.authenticate.secret'
        'spark.eventLog.enabled'
        'spark.yarn.services'
        'spark.history.provider'
        'spark.eventLog.dir'
        'spark.history.fs.logDirectory'
        'spark.ssl.enabledAlgorithms'
        'spark.eventLog.overwrite'
        'spark.yarn.jar'
        'spark.yarn.applicationMaster.waitTries'
        'spark.yarn.am.waitTime'
        'spark.yarn.containerLauncherMaxThreads'
        'spark.yarn.driver.memoryOverhead'
        'spark.yarn.executor.memoryOverhead'
        'spark.yarn.max.executor.failures'
        'spark.yarn.preserve.staging.files'
        'spark.yarn.queue'
        'spark.yarn.scheduler.heartbeat.interval-ms'
        'spark.yarn.services'
        'spark.yarn.submit.file.replication'
      ] then options.conf[prop] ?= service.deps.spark_client.options.conf[prop]

## Tez

Tez configuration directory is injected into "spark-env.sh".

      options.tez_conf_dir = service.deps.tez.options.env['TEZ_CONF_DIR'] if service.deps.tez

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
      options.conf['spark.ssl.trustStore'] ?= service.deps.hadoop_core.options.ssl_client['ssl.client.truststore.location']
      options.conf['spark.ssl.trustStorePassword'] ?= service.deps.hadoop_core.options.ssl_client['ssl.client.truststore.password']

### Kerberos

Spark SQL thrift server is runned in yarn through the hive server user, and must use the hive-server2's keytab

      options.hive_site['hive.server2.authentication.kerberos.principal'] ?= service.deps.hive_server2[0].options.hive_site['hive.server2.authentication.kerberos.principal']
      options.hive_site['hive.server2.authentication.kerberos.keytab'] ?= service.deps.hive_server2[0].options.hive_site['hive.server2.authentication.kerberos.keytab']
      options.conf['spark.yarn.principal'] ?= service.deps.hive_server2[0].options.hive_site['hive.server2.authentication.kerberos.principal'].replace '_HOST', options.fqdn
      options.conf['spark.yarn.keytab'] ?= service.deps.hive_server2[0].options.hive_site['hive.server2.authentication.kerberos.keytab']
      match = /^(.+?)[@\/]/.exec options.conf['spark.yarn.principal']
      throw Error 'SQL Thrift Server principal must mach thrift user name' unless match[1] is options.user_name

# ### Enable Yarn Job submission
# 
#       for srv in service.deps.yarn_nm
#         nm_ctx.before
#           type: 'service'
#           name: 'hadoop-yarn-nodemanager'
#           handler: ->
#             @system.group header: 'Group', service.deps.hive_server2[0].options.group
#             @system.user header: 'User', service.deps.hive_server2[0].options.user
#             @system.mkdir
#               target: service.deps.hive_server2[0].options.user.home

## Wait

      options.wait_krb5_client ?= service.deps.krb5_client.options.wait
      options.wait = {}
      options.wait.thrift = for srv in service.deps.spark_thrift_server
        srv.options.hive_site ?= {}
        srv.options.hive_site['hive.server2.transport.mode'] ?= 'binary'
        srv.options.hive_site['hive.server2.thrift.http.port'] ?= '10015'
        srv.options.hive_site['hive.server2.thrift.port'] ?= '10015'
        host: srv.node.fqdn
        port: if srv.options.hive_site['hive.server2.transport.mode'] is 'http'
        then srv.options.hive_site['hive.server2.thrift.http.port']
        else srv.options.hive_site['hive.server2.thrift.port']

## Dependencies

    {merge} = require 'nikita/lib/misc'

[hdp-spark-sql]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/starting_sts.html)
