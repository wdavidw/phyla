
# Apache Spark Configure

    module.exports = ->
      {core_site, hadoop_conf_dir} = @config.ryba
      nm_ctxs = @contexts 'ryba/hadoop/yarn_nm'
      graphite_ctxs = @contexts 'ryba/graphite/carbon'
      [ganglia_ctx] = @contexts 'ryba/ganglia/collector'
      hcat_ctxs = @contexts 'ryba/hive/hcatalog'
      throw Error "No HCatalog server declared" unless hcat_ctxs[0]
      spark = @config.ryba.spark ?= {}
      spark.conf ?= {}
      # User
      spark.user ?= {}
      spark.user = name: spark.user if typeof spark.user is 'string'
      spark.user.name ?= 'spark'
      spark.user.system ?= true
      spark.user.comment ?= 'Spark User'
      spark.user.home ?= '/var/lib/spark'
      spark.user.groups ?= 'hadoop'
      # Group
      spark.group ?= {}
      spark.group = name: spark.group if typeof spark.group is 'string'
      spark.group.name ?= 'spark'
      spark.group.system ?= true
      spark.user.gid ?= spark.group.name
      # Configuration
      spark.conf ?= {}
      spark.conf['spark.master'] ?= "local[*]"
      # For [Spark on YARN deployments][[secu]], configuring spark.authenticate to true
      # will automatically handle generating and distributing the shared secret.
      # Each application will use a unique shared secret. 
      # http://spark.apache.org/docs/1.6.0/configuration.html#security
      spark.conf['spark.authenticate'] ?= "true"
      if spark.conf['spark.authenticate']
        spark.conf['spark.authenticate.secret'] ?= 'my-secret-key' 
        throw Error 'spark.authenticate.secret is needed when spark.authenticate is true' unless spark.conf['spark.authenticate.secret']
      # This causes Spark applications running on this client to write their history to the directory that the history server reads.
      spark.conf['spark.eventLog.enabled'] ?= "true"
      spark.conf['spark.yarn.services'] ?= "org.apache.spark.deploy.yarn.history.YarnHistoryService"
      # set to only supported one http://spark.apache.org/docs/1.6.0/monitoring.html#viewing-after-the-fact
      # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_upgrading_hdp_manually/content/upgrade-spark-23.html
      spark.conf['spark.history.provider'] ?= 'org.apache.spark.deploy.history.FsHistoryProvider'
      # Base directory in which Spark events are logged, if spark.eventLog.enabled is true.
      # Within this base directory, Spark creates a sub-directory for each application, and logs the events specific to the application in this directory.
      # Users may want to set this to a unified location like an HDFS directory so history files can be read by the history server.
      spark.conf['spark.eventLog.dir'] ?= "#{core_site['fs.defaultFS']}/user/#{spark.user.name}/applicationHistory"
      spark.conf['spark.history.fs.logDirectory'] ?= "#{spark.conf['spark.eventLog.dir']}"
      spark.client_dir ?= '/usr/hdp/current/spark-client'
      spark.conf_dir ?= '/etc/spark/conf'
      # For now on spark 1.3, [SSL is falling][secu] even after distributing keystore
      # and trustore on worker nodes as suggested in official documentation.
      # Maybe we shall share and deploy public keys instead of just the cacert
      # Disabling for now 
      spark.conf['spark.ssl.enabled'] ?= "false"
      spark.conf['spark.ssl.enabledAlgorithms'] ?= "MD5"
      spark.conf['spark.ssl.keyPassword'] ?= "ryba123"
      spark.conf['spark.ssl.keyStore'] ?= "#{spark.conf_dir}/keystore"
      spark.conf['spark.ssl.keyStorePassword'] ?= "ryba123"
      spark.conf['spark.ssl.protocol'] ?= "SSLv3"
      spark.conf['spark.ssl.trustStore'] ?= "#{spark.conf_dir}/trustore"
      spark.conf['spark.ssl.trustStorePassword'] ?= "ryba123"
      spark.conf['spark.eventLog.overwrite'] ?= 'true'
      spark.conf['spark.yarn.jar'] ?= "hdfs:///apps/#{spark.user.name}/spark-assembly.jar"
      # spark.conf['spark.yarn.applicationMaster.waitTries'] = null Deprecated in favor of "spark.yarn.am.waitTime"
      spark.conf['spark.yarn.am.waitTime'] ?= '10'
      spark.conf['spark.yarn.containerLauncherMaxThreads'] ?= '25'
      spark.conf['spark.yarn.driver.memoryOverhead'] ?= '384'
      spark.conf['spark.yarn.executor.memoryOverhead'] ?= '384'
      spark.conf['spark.yarn.max.executor.failures'] ?= '3'
      spark.conf['spark.yarn.preserve.staging.files'] ?= 'false'
      spark.conf['spark.yarn.queue'] ?= 'default'
      spark.conf['spark.yarn.scheduler.heartbeat.interval-ms'] ?= '5000'
      spark.conf['spark.yarn.services'] ?= 'org.apache.spark.deploy.yarn.history.YarnHistoryService'
      spark.conf['spark.yarn.submit.file.replication'] ?= '3'
      spark.dist_files ?= []

## Client Metastore Configuration
Spark needs hive-site.xml in order to create hive spark context. Spark is client
towards hive/hcatalog and needs its client configuration.
the hive-site.xml is set inside /etc/spark/conf/ dir.

      spark.hive ?= {}
      spark.hive.site ?= {}
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
      ] then spark.hive.site[property] ?= hcat_ctxs[0].config.ryba.hive.hcatalog.site[property]
      spark.hive.site['hive.execution.engine'] ?= 'mr'

[secu]: http://spark.apache.org/docs/latest/security.html

## Metrics

Configure the "metrics.properties" to connect Spark to a metrics collector like Ganglia or Graphite.
The metrics.properties file needs to be sent to every executor, 
and spark.metrics.conf=metrics.properties will tell all executors to load that file when initializing their respective MetricsSystems

      # spark.conf['spark.metrics.conf'] ?= 'metrics.properties'
      spark.conf_metrics ?= false
      if spark.conf_metrics
        spark.conf['spark.metrics.conf'] ?= "metrics.properties" # Error, spark complain it cant find if value is 'metrics.properties'
        if spark.conf['spark.metrics.conf']?
          spark.dist_files.push "file://#{spark.conf_dir}/metrics.properties" unless spark.dist_files.indexOf "file://#{spark.conf_dir}/metrics.properties" is -1
        spark.metrics =
          'master.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
          'worker.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
          'driver.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'
          'executor.source.jvm.class':'org.apache.spark.metrics.source.JvmSource'

        if graphite_ctxs.length
          spark.metrics['*.sink.graphite.class'] = 'org.apache.spark.metrics.sink.GraphiteSink'
          spark.metrics['*.sink.graphite.host'] = graphite_ctxs.map( (ctx) -> ctx.config.host)
          spark.metrics['*.sink.graphite.port'] = graphite_ctxs[0].config.ryba.graphite.carbon_aggregator_port
          spark.metrics['*.sink.graphite.prefix'] = "#{graphite_ctxs[0].config.ryba.graphite.metrics_prefix}.spark"

        # TODO : metrics.MetricsSystem: Sink class org.apache.spark.metrics.sink.GangliaSink cannot be instantialized
        if false #ctx.host_with_module 'ryba/ganglia/collector'
          ganglia_ctx.config.ryba.ganglia
          spark.metrics['*.sink.ganglia.class'] = 'org.apache.spark.metrics.sink.GangliaSink'
          spark.metrics['*.sink.ganglia.host'] = graphite_ctx.map( (ctx) -> ctx.config.host)
          spark.metrics['*.sink.ganglia.port'] = ganglia_ctx.spark_port
      spark.conf['spark.yarn.dist.files'] ?= spark.dist_files.join(',') if spark.dist_files.length > 0

## Dynamic Resource Allocation

Spark mecanism to set up resources based on cluster availability

      #http://spark.apache.org/docs/1.6.0/job-scheduling.html#dynamic-resource-allocation
      spark.conf['spark.dynamicAllocation.enabled'] ?= 'false' #disable by default
      spark.conf['spark.shuffle.service.enabled'] ?= spark.conf['spark.dynamicAllocation.enabled']
      if spark.conf['spark.dynamicAllocation.enabled'] is 'true'
        spark.conf['spark.shuffle.service.port'] ?= '56789'
        for nm_ctx in nm_ctxs
          aux_services  = nm_ctx.config.ryba.yarn.site['yarn.nodemanager.aux-services'].split ','
          aux_services.push 'spark_shuffle' unless 'spark_shuffle' in aux_services
          nm_ctx.config.ryba.yarn.site['yarn.nodemanager.aux-services'] = aux_services.join ','
          nm_ctx.config.ryba.yarn.site['yarn.nodemanager.aux-services.spark_shuffle.class'] ?= 'org.apache.spark.network.yarn.YarnShuffleService'
          nm_ctx.config.ryba.yarn.site['spark.shuffle.service.enabled'] ?= 'true'
          nm_ctx
          .after
            type: ['hconfigure']
            target: "#{nm_ctx.config.ryba.yarn.nm.conf_dir}/yarn-site.xml"
            handler: (options, callback) ->
              nm_ctx
              .iptables
                header: 'Spark YARN Shuffle Service Port'
                ssh: options.ssh
                rules: [
                  { chain: 'INPUT', jump: 'ACCEPT', dport: spark.conf['spark.shuffle.service.port'], protocol: 'tcp', state: 'NEW', comment: "Spark YARN Shuffle Service" }
                ]
                if: nm_ctx.config.iptables.action is 'start'
              .then callback
