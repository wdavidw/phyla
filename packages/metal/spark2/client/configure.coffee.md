
# Apache Spark Configure

    module.exports = (service) ->
      options = service.options

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'spark'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'spark'
      options.user.system ?= true
      options.user.comment ?= 'Spark User'
      options.user.home ?= '/var/lib/spark'
      options.user.groups ?= 'hadoop'
      options.user.gid ?= options.group.name

## Kerberos

      # Kerberos HDFS Admin
      options.hdfs_krb5_user ?= service.deps.hadoop_core.options.hdfs.krb5_user
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.client_dir ?= '/usr/hdp/current/spark2-client'
      options.conf_dir ?= '/etc/spark2/conf'
      # Misc
      options.hostname = service.node.hostname
      # options.hdfs_defaultfs = service.deps.hdfs_nn[0].options.core_site['fs.defaultFS']

## Tez

Tez configuration directory is injected into "spark-env.sh".

      options.tez_conf_dir = service.deps.tez.options.env['TEZ_CONF_DIR'] if service.deps.tez

## Hive server2


## Test

      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin
      options.ranger_install = service.deps.ranger_hive[0].options.install if service.deps.ranger_hive
      options.test = merge service.deps.test_user.options, options.test
      # Hive Server2
      if service.deps.hive_server2
        options.hive_server2 = for srv in service.deps.hive_server2
          fqdn: srv.options.fqdn
          hostname: srv.options.hostname
          hive_site: srv.options.hive_site

## Configuration

      options.conf ?= {}
      options.conf['spark.master'] ?= "local[*]"
      # For [Spark on YARN deployments][[secu]], configuring spark.authenticate to true
      # will automatically handle generating and distributing the shared secret.
      # Each application will use a unique shared secret. 
      # http://spark.apache.org/docs/1.6.0/configuration.html#security
      options.conf['spark.authenticate'] ?= "true"
      if options.conf['spark.authenticate']
        options.conf['spark.authenticate.secret'] ?= 'my-secret-key' 
        throw Error 'spark.authenticate.secret is needed when spark.authenticate is true' unless options.conf['spark.authenticate.secret']
      # This causes Spark applications running on this client to write their history to the directory that the history server reads.
      options.conf['spark.eventLog.enabled'] ?= "true"
      options.conf['spark.yarn.services'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryService"
      # set to only supported one http://spark.apache.org/docs/1.6.0/monitoring.html#viewing-after-the-fact
      # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_upgrading_hdp_manually/content/upgrade-spark-23.html
      options.conf['spark.history.provider'] ?= 'org.apache.spark.deploy.history.FsHistoryProvider'
      # Base directory in which Spark events are logged, if spark.eventLog.enabled is true.
      # Within this base directory, Spark creates a sub-directory for each application, and logs the events specific to the application in this directory.
      # Users may want to set this to a unified location like an HDFS directory so history files can be read by the history server.
      options.conf['spark.eventLog.dir'] ?= "#{service.deps.hdfs_nn[0].options.core_site['fs.defaultFS']}/user/#{options.user.name}/applicationHistory"
      options.conf['spark.history.fs.logDirectory'] ?= "#{options.conf['spark.eventLog.dir']}"
      options.conf['spark.eventLog.overwrite'] ?= 'true'
      options.conf['spark.yarn.jar'] ?= "hdfs:///apps/#{options.user.name}/spark-assembly.jar"
      # options.conf['spark.yarn.applicationMaster.waitTries'] = null Deprecated in favor of "spark.yarn.am.waitTime"
      options.conf['spark.yarn.am.waitTime'] ?= '10'
      options.conf['spark.yarn.containerLauncherMaxThreads'] ?= '25'
      options.conf['spark.yarn.driver.memoryOverhead'] ?= '384'
      options.conf['spark.yarn.executor.memoryOverhead'] ?= '384'
      options.conf['spark.yarn.max.executor.failures'] ?= '3'
      options.conf['spark.yarn.preserve.staging.files'] ?= 'false'
      options.conf['spark.yarn.queue'] ?= 'default'
      options.conf['spark.yarn.scheduler.heartbeat.interval-ms'] ?= '5000'
      options.conf['spark.yarn.services'] ?= 'org.apache.spark.deploy.yarn.history.YarnHistoryService'
      options.conf['spark.yarn.submit.file.replication'] ?= '3'
      options.dist_files ?= []

## SSL

      options.ssl = merge service.deps.ssl.options, options.ssl
      options.conf['spark.ssl.enabled'] ?= "false" # `!!service.deps.ssl`
      # options.conf['spark.ssl.enabledAlgorithms'] ?= "MD5"
      options.conf['spark.ssl.keyPassword'] ?= service.deps.ssl.options.keystore.password
      options.conf['spark.ssl.keyStore'] ?= "#{options.conf_dir}/keystore"
      options.conf['spark.ssl.keyStorePassword'] ?= service.deps.ssl.options.keystore.password
      options.conf['spark.ssl.protocol'] ?= "SSLv3"
      options.conf['spark.ssl.trustStore'] ?= "#{options.conf_dir}/truststore"
      options.conf['spark.ssl.trustStorePassword'] ?= service.deps.ssl.options.truststore.password

## Client Metastore Configuration
Spark needs hive-site.xml in order to create hive spark context. Spark is client
towards hive/hcatalog and needs its client configuration.
the hive-site.xml is set inside /etc/spark/conf/ dir.

      options.hive_site ?= {}
      for property in [
        'hive.metastore.uris'
        'hive.security.authorization.enabled'
        'hive.security.authorization.manager'
        'hive.security.metastore.authorization.manager'
        'hive.security.authenticator.manager'
        # Transaction, read/write locks
        'hive.support.concurrency'
        'hive.enforce.bucketing'
        'hive.exec.dynamic.partition.mode'
        'hive.txn.manager'
        'hive.txn.timeout'
        'hive.txn.max.open.batch'
        'hive.cluster.delegation.token.store.zookeeper.connectString'
        # 'hive.cluster.delegation.token.store.class'
        # 'hive.metastore.local'
        # 'fs.hdfs.impl.disable.cache'
        'hive.metastore.sasl.enabled'
        # 'hive.metastore.cache.pinobjtypes'
        # 'hive.metastore.kerberos.keytab.file'
        'hive.metastore.kerberos.principal'
        # 'hive.metastore.pre.event.listeners'
        'hive.optimize.mapjoin.mapreduce'
        'hive.heapsize'
        'hive.auto.convert.sortmerge.join.noconditionaltask'
        'hive.exec.max.created.files'
        'hive.metastore.warehouse.dir'
        # Transaction, read/write locks
      ] then options.hive_site[property] ?= service.deps.hive_hcatalog[0].options.hive_site[property]
      options.hive_site['hive.execution.engine'] ?= 'mr'

[secu]: http://spark.apache.org/docs/latest/security.html

## Metrics

Configure the "metrics.properties" to connect Spark to a metrics collector like Ganglia or Graphite.
The metrics.properties file needs to be sent to every executor, 
and spark.metrics.conf=metrics.properties will tell all executors to load that file when initializing their respective MetricsSystems

      # options.conf['spark.metrics.conf'] ?= 'metrics.properties'
      options.conf_metrics ?= false
      if options.conf_metrics
        options.conf['spark.metrics.conf'] ?= "metrics.properties" # Error, spark complain it cant find if value is 'metrics.properties'
        if options.conf['spark.metrics.conf']?
          options.dist_files.push "file://#{options.conf_dir}/metrics.properties" unless options.dist_files.indexOf "file://#{options.conf_dir}/metrics.properties" is -1
        options.metrics =
          'master.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
          'worker.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
          'driver.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
          'executor.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'

        if service.deps.graphite
          options.metrics['*.sink.graphite.class'] = 'org.apache.spark.metrics.sink.GraphiteSink'
          options.metrics['*.sink.graphite.host'] = service.deps.graphite[0].instances.map( (instance) -> instance.node.fqdn ).join ','
          options.metrics['*.sink.graphite.port'] = graphite_ctxs[0].config.ryba.graphite[0].options.carbon_aggregator_port
          options.metrics['*.sink.graphite.prefix'] = "#{graphite_ctxs[0].config.ryba.graphite[0].options.metrics_prefix}.spark"

        # TODO : metrics.MetricsSystem: Sink class org.apache.spark.metrics.sink.GangliaSink cannot be instantialized
        if service.deps.ganglia_collector
          options.metrics['*.sink.ganglia.class'] = 'org.apache.spark.metrics.sink.GangliaSink'
          options.metrics['*.sink.ganglia.host'] = service.deps.ganglia_collector[0].instances.map( (instance) -> instance.node.fqdn ).join ','
          options.metrics['*.sink.ganglia.port'] = service.deps.ganglia_collector[0].options.spark_port
      options.conf['spark.yarn.dist.files'] ?= options.dist_files.join(',') if options.dist_files.length > 0

## Dynamic Resource Allocation

Spark mecanism to set up resources based on cluster availability

      #http://spark.apache.org/docs/1.6.0/job-scheduling.html#dynamic-resource-allocation
      options.conf['spark.dynamicAllocation.enabled'] ?= 'false' #disable by default
      options.conf['spark.shuffle.service.enabled'] ?= options.conf['spark.dynamicAllocation.enabled']
      if options.conf['spark.dynamicAllocation.enabled'] is 'true'
        options.conf['spark.shuffle.service.port'] ?= '56789'
        for srv in service.deps.yarn_nm
          aux_services  = srv.options.yarn_site['yarn.nodemanager.aux-services'].split ','
          aux_services.push 'spark_shuffle' unless 'spark_shuffle' in aux_services
          srv.options.yarn_site['yarn.nodemanager.aux-services'] = aux_services.join ','
          srv.options.yarn_site['yarn.nodemanager.aux-services.spark_shuffle.class'] ?= 'org.apache.spark.network.yarn.YarnShuffleService'
          srv.options.yarn_site['spark.shuffle.service.enabled'] ?= 'true'
          srv.options.iptables_rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: options.conf['spark.shuffle.service.port'], protocol: 'tcp', state: 'NEW', comment: "Spark YARN Shuffle Service" }

## Wait

      options.wait_yarn_rm = service.deps.yarn_rm[0].options.wait
      options.wait_ranger_admin = service.deps.ranger_admin.options.wait if service.deps.ranger_admin

## Dependencies

    {merge} = require 'mixme'
