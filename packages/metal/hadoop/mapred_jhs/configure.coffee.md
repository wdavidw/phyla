
# MapReduce JobHistoryServer (JHS) Configure

    module.exports = (service) ->
      options = service.options

## Identities

      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.deps.hadoop_core.options.mapred.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.mapred.user, options.user

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.home ?= '/usr/hdp/current/hadoop-yarn-nodemanager'
      options.log_dir ?= '/var/log/hadoop/mapreduce'
      options.pid_dir ?= '/var/run/hadoop/mapreduce'
      options.conf_dir ?= '/etc/hadoop-mapreduce-historyserver/conf'
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.hadoop_heap ?= service.deps.hadoop_core.options.hadoop_heap
      options.hadoop_opts ?= service.deps.hadoop_core.options.hadoop_opts
      options.hadoop_client_opts ?= service.deps.hadoop_core.options.hadoop_client_opts
      options.heapsize ?= '900'
      # Misc
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## Configuration

      # Hadoop core "core-site.xml"
      options.core_site = merge {}, service.deps.hdfs_client[0].options.core_site, options.core_site or {}
      # HDFS client "hdfs-site.xml"
      options.hdfs_site = merge {}, service.deps.hdfs_client[0].options.hdfs_site, options.hdfs_site or {}
      # YARN client "yarn-site.xml"
      # Options will be exported by the YARN RM
      options.yarn_site ?= {}
      # MapRed JHS "mapred-site.xml"
      options.mapred_site ?= {}
      options.mapred_site['mapreduce.jobhistory.keytab'] ?= "/etc/security/keytabs/jhs.service.keytab"
      options.mapred_site['mapreduce.jobhistory.principal'] ?= "jhs/#{service.node.fqdn}@#{options.krb5.realm}"
      # Fix: src in "[DFSConfigKeys.java][keys]" and [HDP port list] mention 13562 while companion files mentions 8081
      options.mapred_site['mapreduce.shuffle.port'] ?= '13562'
      options.mapred_site['mapreduce.jobhistory.address'] ?= "#{service.node.fqdn}:10020"
      options.mapred_site['mapreduce.jobhistory.webapp.address'] ?= "#{service.node.fqdn}:19888"
      options.mapred_site['mapreduce.jobhistory.webapp.https.address'] ?= "#{service.node.fqdn}:19889"
      options.mapred_site['mapreduce.jobhistory.admin.address'] ?= "#{service.node.fqdn}:10033"

Note: As of version "2.4.0", the property "mapreduce.jobhistory.http.policy"
isn't honored. Instead, the property "yarn.http.policy" is used. It is exported 
from the yarn_rm.

      # options.yarn_site['yarn.http.policy'] ?= service.deps.yarn_rm.options.yarn_site['yarn.http.policy']
      options.mapred_site['mapreduce.jobhistory.http.policy'] ?= 'HTTPS_ONLY'
      # See './hadoop-mapreduce-project/hadoop-mapreduce-client/hadoop-mapreduce-client-common/src/main/java/org/apache/hadoop/mapreduce/v2/jobhistory/JHAdminConfig.java#158'
      # yarn.site['mapreduce.jobhistory.webapp.spnego-principal']
      # yarn.site['mapreduce.jobhistory.webapp.spnego-keytab-file']

## Configuration for Staging Directories

The property "yarn.app.mapreduce.am.staging-dir" is an alternative to "done-dir"
and "intermediate-done-dir". According to Cloudera: Configure 
mapreduce.jobhistory.intermediate-done-dir and mapreduce.jobhistory.done-dir in
mapred-site.xml. Create these two directories. Set permissions on
mapreduce.jobhistory.intermediate-done-dir to 1777. Set permissions on
mapreduce.jobhistory.done-dir to 750.

If "yarn.app.mapreduce.am.staging-dir" is active (if the other two are unset),
a folder history must be created and own by the mapreduce user. On startup, JHS
will create two folders:

```bash
hdfs dfs -ls /user/history
Found 2 items
drwxrwx---   - mapred hadoop          0 2015-08-04 23:21 /user/history/done
drwxrwxrwt   - mapred hadoop          0 2015-08-04 23:21 /user/history/done_intermediate
```

      options.mapred_site['yarn.app.mapreduce.am.staging-dir'] = "/user" # default to "/tmp/hadoop-yarn/staging"
      # options.mapred_site['mapreduce.jobhistory.done-dir'] ?= '/mr-history/done' # Directory where history files are managed by the MR JobHistory Server.
      # options.mapred_site['mapreduce.jobhistory.intermediate-done-dir'] ?= '/mr-history/tmp' # Directory where history files are written by MapReduce jobs.
      options.mapred_site['mapreduce.jobhistory.done-dir'] = null
      options.mapred_site['mapreduce.jobhistory.intermediate-done-dir'] = null

## Job Recovery

The following properties provides persistent state to the Job history server.
They are referenced by [the druid hadoop configuration][druid] and
[the Ambari 2.3 stack][amb-mr-site]. Job Recovery is activated by default.   

      options.mapred_site['mapreduce.jobhistory.recovery.enable'] ?= 'true'
      options.mapred_site['mapreduce.jobhistory.recovery.store.class'] ?= 'org.apache.hadoop.mapreduce.v2.hs.HistoryServerLeveldbStateStoreService'
      options.mapred_site['mapreduce.jobhistory.recovery.store.leveldb.path'] ?= '/var/mapred/jhs'

## SSL

      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl
      options.ssl_server = merge {}, service.deps.hadoop_core.options.ssl_server, options.ssl_server or {},
        'ssl.server.keystore.location': "#{options.conf_dir}/keystore"
        'ssl.server.truststore.location': "#{options.conf_dir}/truststore"
      options.ssl_client = merge {}, service.deps.hadoop_core.options.ssl_client, options.ssl_client or {},
        'ssl.client.truststore.location': "#{options.conf_dir}/truststore"

## Metrics

      options.metrics = merge {}, service.deps.hadoop_core.options.metrics, options.metrics
      options.metrics.config ?= {}
      if options.metrics.sinks.file_enabled
        options.metrics.config["*.sink.file.#{k}"] ?= v for k, v of options.metrics.sinks.file
      if options.metrics.sinks.graphite_enabled
        throw Error 'Unvalid metrics sink, please provide ryba.metrics.sinks.graphite.config.server_host and server_port' unless options.metrics.sinks.graphite.config.server_host? and options.metrics.sinks.graphite.config.server_port?
        options.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of options.metrics.sinks.graphite.config
        options.metrics.config["historyserver.sink.graphite.class"] ?= options.metrics.sinks.graphite.class
        options.metrics.config["mrappmaster.sink.graphite.class"] ?= options.metrics.sinks.graphite.class

## Metrics

      options.metrics = merge {}, service.deps.metrics?.options, options.metrics

      options.metrics.config ?= {}
      options.metrics.sinks ?= {}
      options.metrics.sinks.file_enabled ?= true
      options.metrics.sinks.ganglia_enabled ?= false
      options.metrics.sinks.graphite_enabled ?= false
      # File sink
      if options.metrics.sinks.file_enabled
        options.metrics.config["*.sink.file.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.file.config if service.deps.metrics?.options?.sinks?.file_enabled
        options.metrics.config['mrappmaster.sink.file.class'] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        options.metrics.config['jobhistoryserver.sink.file.class'] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        options.metrics.config['mrappmaster.sink.file.filename'] ?= 'mrappmaster-metrics.out'
        options.metrics.config['jobhistoryserver.sink.file.filename'] ?= 'jobhistoryserver-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if options.metrics.sinks.ganglia_enabled
        options.metrics.config["mrappmaster.sink.ganglia.class"] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
        options.metrics.config["jobhistoryserver.sink.ganglia.class"] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
        options.metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of options.sinks.ganglia.config if service.deps.metrics?.options?.sinks?.ganglia_enabled
      # Graphite Sink
      if options.metrics.sinks.graphite_enabled
        throw Error 'Missing remote_host ryba.mapred_jhs.metrics.sinks.graphite.config.server_host' unless options.metrics.sinks.graphite.config.server_host?
        throw Error 'Missing remote_port ryba.mapred_jhs.metrics.sinks.graphite.config.server_port' unless options.metrics.sinks.graphite.config.server_port?
        options.metrics.config["mrappmaster.sink.graphite.class"] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config["jobhistoryserver.sink.graphite.class"] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.graphite.config if service.deps.metrics?.options?.sinks?.graphite_enabled

## Wait

      options.wait_hdfs_nn ?= service.deps.hdfs_nn[0].options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.deps.mapred_jhs
        srv.options.mapred_site ?= {}
        srv.options.mapred_site['mapreduce.jobhistory.address'] ?= "#{srv.node.fqdn}:10020"
        [fqdn, port] = srv.options.mapred_site['mapreduce.jobhistory.address'].split ':'
        host: fqdn, port: port
      options.wait.webapp = for srv in service.deps.mapred_jhs
        protocol = if options.mapred_site['mapreduce.jobhistory.http.policy'] is 'HTTP_ONLY' then '' else 'https.'
        srv.options.mapred_site ?= {}
        srv.options.mapred_site['mapreduce.jobhistory.webapp.address'] ?= "#{srv.node.fqdn}:19888"
        srv.options.mapred_site['mapreduce.jobhistory.webapp.https.address'] ?= "#{srv.node.fqdn}:19889"
        [fqdn, port] = srv.options.mapred_site["mapreduce.jobhistory.webapp.#{protocol}address"].split ':'
        host: fqdn, port: port

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
