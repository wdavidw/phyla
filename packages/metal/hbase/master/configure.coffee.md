
# HBase Master Configuration

    module.exports = (service) ->
      options = service.options

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]

## Identities

* `admin` (object|string)
  The Kerberos HBase principal.
* `group` (object|string)
  The Unix HBase group name or a group object (see Nikita Group documentation).
* `user` (object|string)
  The Unix HBase login name or a user object (see Nikita User documentation).

Example

```json
{
  "user": {
    "name": "hbase", "system": true, "gid": "hbase", groups: "hadoop",
    "comment": "HBase User", "home": "/var/run/hbase"
  },
  "group": {
    "name": "HBase", "system": true
  },
  "admin": {
    "password": "hbase123"
  }
}
```

      # Hadoop Group
      options.hadoop_group = merge service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'hbase'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'hbase'
      options.user.system ?= true
      options.user.gid = options.group.name
      options.user.comment ?= 'HBase User'
      options.user.home ?= '/var/run/hbase'
      options.user.groups ?= 'hadoop'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= true
      # Kerberos Hbase Admin Principal
      options.admin ?= {}
      options.admin.name ?= options.user.name
      options.admin.principal ?= "#{options.admin.name}@#{options.krb5.realm}"
      throw Error 'Required Option: admin.password' unless options.admin.password

## Kerberos

      # Kerberos HDFS Admin
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.conf_dir ?= '/etc/hbase-master/conf'
      options.log_dir ?= '/var/log/hbase'
      options.pid_dir ?= '/var/run/hbase'
      # Env
      options.env ?= {}
      options.env['HBASE_LOG_DIR'] ?= "#{options.log_dir}"
      options.env['HBASE_OPTS'] ?= '-XX:+UseConcMarkSweepGC ' # -XX:+CMSIncrementalMode is deprecated
      # Java
      # 'HBASE_MASTER_OPTS' ?= '-Xmx2048m' # Default in HDP companion file
      options.java_home ?= "#{service.deps.java.options.java_home}"
      options.heapsize ?= '1024m'
      options.newsize ?= '200m'
      # Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false
      # HDFS
      options.hdfs_conf_dir ?= service.deps.hadoop_core.options.conf_dir
      options.hdfs_krb5_user ?= service.deps.hadoop_core.options.hdfs.krb5_user

## System Options

      options.opts ?= {}
      options.opts.base ?= ''
      options.opts.java_properties ?= {}
      options.opts.jvm ?= {}
      options.opts.jvm['-Xms'] ?= options.heapsize
      options.opts.jvm['-Xmx'] ?= options.heapsize
      options.opts.jvm['-XX:NewSize='] ?= options.newsize #should be 1/8 of hbase master heapsize
      options.opts.jvm['-XX:MaxNewSize='] ?= options.newsize #should be 1/8 of hbase master heapsize

## RegionServers

RegionServer must register to the Master, the key is the FQDN while the value
activate or desactivate the RegionServer.

      options.regionservers ?= {}

## Configuration

      # HBase "hbase-site.xml"
      options.hbase_site ?= {}
      options.hbase_site['hbase.master.port'] ?= '60000'
      options.hbase_site['hbase.master.info.port'] ?= '60010'
      options.hbase_site['hbase.master.info.bindAddress'] ?= '0.0.0.0'
      options.hbase_site['hbase.ssl.enabled'] ?= 'true'

## Configuration Distributed mode

      options.hbase_site['zookeeper.znode.parent'] ?= '/hbase'
      # The mode the cluster will be in. Possible values are
      # false: standalone and pseudo-distributed setups with managed Zookeeper
      # true: fully-distributed with unmanaged Zookeeper Quorum (see hbase-env.sh)
      options.hbase_site['hbase.cluster.distributed'] = 'true'
      options.hbase_site['zookeeper.session.timeout'] ?= "#{20 * parseInt service.deps.zookeeper_server[0].options.config['tickTime']}"
      # Enter the HBase NameNode server hostname
      # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-High-Availability-Guide/cdh4hag_topic_2_6.html
      options.hbase_site['hbase.rootdir'] ?= "#{service.deps.hdfs_nn[0].options.core_site['fs.defaultFS']}/apps/hbase/data"
      # Comma separated list of Zookeeper servers (match to
      # what is specified in zoo.cfg but without portnumbers)
      options.hbase_site['hbase.zookeeper.quorum'] ?= service.deps.zookeeper_server.map( (srv) -> srv.node.fqdn ).join ','
      options.hbase_site['hbase.zookeeper.property.clientPort'] ?= service.deps.zookeeper_server[0].options.config['clientPort']
      throw Error "Required Option: hbase_site['hbase.zookeeper.quorum']" unless options.hbase_site['hbase.zookeeper.quorum']
      throw Error "Required Option: hbase_site['hbase.zookeeper.property.clientPort']" unless options.hbase_site['hbase.zookeeper.property.clientPort']
      # Short-circuit are true but socket.path isnt defined for hbase, only for hdfs, see http://osdir.com/ml/hbase-user-hadoop-apache/2013-03/msg00007.html
      # options.hbase_site['dfs.domain.socket.path'] ?= hdfs.site['dfs.domain.socket.path']
      options.hbase_site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'

## Configuration for Kerberos

      options.hbase_site['hbase.security.authentication'] ?= 'kerberos' # Required by HM, RS and client
      if options.hbase_site['hbase.security.authentication'] is 'kerberos'
        options.hbase_site['hbase.master.keytab.file'] ?= '/etc/security/keytabs/hm.service.keytab'
        options.hbase_site['hbase.master.kerberos.principal'] ?= "hbase/_HOST@#{options.krb5.realm}" # "hm/_HOST@#{realm}" <-- need zookeeper auth_to_local
        options.hbase_site['hbase.regionserver.kerberos.principal'] ?= "hbase/_HOST@#{options.krb5.realm}" # "rs/_HOST@#{realm}" <-- need zookeeper auth_to_local
        options.hbase_site['hbase.security.authentication.ui'] ?= 'kerberos'
        options.hbase_site['hbase.security.authentication.spnego.kerberos.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
        options.hbase_site['hbase.security.authentication.spnego.kerberos.keytab'] ?= service.deps.hadoop_core.options.core_site['hadoop.http.authentication.kerberos.keytab']
        options.hbase_site['hbase.coprocessor.master.classes'] ?= [
          'org.apache.hadoop.hbase.security.access.AccessController'
        ]
        # master be able to communicate with regionserver
        options.hbase_site['hbase.coprocessor.region.classes'] ?= [
          'org.apache.hadoop.hbase.security.token.TokenProvider'
          'org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint'
          'org.apache.hadoop.hbase.security.access.AccessController'
        ]

## Configuration for Security

Bulk loading in secure mode is a bit more involved than normal setup, since the
client has to transfer the ownership of the files generated from the mapreduce
job to HBase. Secure bulk loading is implemented by a coprocessor, named
[SecureBulkLoadEndpoint] and use an HDFS directory which is world traversable
(-rwx--x--x, 711).

      options.hbase_site['hbase.security.authorization'] ?= 'true'
      options.hbase_site['hbase.rpc.engine'] ?= 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
      options.hbase_site['hbase.superuser'] ?= options.admin.name
      options.hbase_site['hbase.bulkload.staging.dir'] ?= '/apps/hbase/staging'
      # Jaas file
      options.opts.java_properties['java.security.auth.login.config'] ?= "#{options.conf_dir}/hbase-master.jaas"

## Configuration for Local Access

      # migration: wdavidw 170902, shouldnt this only apply to the RegionServer ?
      # # HDFS NN
      # for srv in service.deps.hdfs_nn
      #   srv.options.hdfs_site ?= {}
      #   srv.options.hdfs_site['dfs.block.local-path-access.user'] ?= ''
      #   users = srv.options.hdfs_site['dfs.block.local-path-access.user'].split(',').filter (str) -> str isnt ''
      #   users.push 'hbase' unless options.user.name in users
      #   srv.options.hdfs_site['dfs.block.local-path-access.user'] = users.sort().join ','
      # # HDFS DN
      # srv = service.deps.hdfs_dn
      # srv.options.hdfs_site['dfs.block.local-path-access.user'] ?= ''
      # users = srv.options.hdfs_site['dfs.block.local-path-access.user'].split(',').filter (str) -> str isnt ''
      # users.push 'hbase' unless options.user.name in users
      # srv.options.hdfs_site['dfs.block.local-path-access.user'] = users.sort().join ','

## Configuration for High Availability Reads (HA Reads)

*   [Hortonworks presentation of HBase HA](http://hortonworks.com/blog/apache-hbase-high-availability-next-level/)
*   [HDP 2.5 Read HA instruction](https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_hadoop-high-availability/content/config-ha-reads-hbase.html)
*   [Bring quorum based write ahead log (write HA)](https://issues.apache.org/jira/browse/HBASE-12259)

## Async WAL Replication

WAL Replication is enabled by default but should be discovered based on the
number of RegionServer (>2). However, this would introduce a circular
dependency between the Master and the RegionServers.

TODO migration: wdavidw 170829, disable 'hbase.meta.replicas.use' from the
RS if RS count < 3.

      # enable hbase:meta region replication
      options.hbase_site['hbase.meta.replicas.use'] ?= 'true'
      options.hbase_site['hbase.meta.replica.count'] ?= '3' # Default to '1'
      # enable replication for ervery regions
      options.hbase_site['hbase.region.replica.replication.enabled'] ?= 'true'
      # increase default time when 'hbase.region.replica.replication.enabled' is true
      options.hbase_site['hbase.region.replica.wait.for.primary.flush'] ?= 'true'
      options.hbase_site['hbase.master.loadbalancer.class'] = 'org.apache.hadoop.hbase.master.balancer.StochasticLoadBalancer' # Default value
      # StoreFile Refresher
      options.hbase_site['hbase.regionserver.storefile.refresh.period'] ?= '30000' # Default to '0'
      options.hbase_site['hbase.regionserver.meta.storefile.refresh.period'] ?= '30000' # Default to '0'
      options.hbase_site['hbase.region.replica.storefile.refresh.memstore.multiplier'] ?= '4'
      # HFile TTL must be greater than refresher period
      options.hbase_site['hbase.master.hfilecleaner.ttl'] ?= '3600000' # 1 hour

## Configuration Region Server Groups

      # see https://hbase.apache.org/book.html#rsgroup
      options.rsgroups_enabled ?= false
      if options.rsgroups_enabled
        options.hbase_site['hbase.master.loadbalancer.class'] = 'org.apache.hadoop.hbase.rsgroup.RSGroupBasedLoadBalancer'
        options.hbase_site['hbase.coprocessor.master.classes'].push 'org.apache.hadoop.hbase.rsgroup.RSGroupAdminEndpoint' unless 'org.apache.hadoop.hbase.rsgroup.RSGroupAdminEndpoint' in options.hbase_site['hbase.coprocessor.master.classes']

## Configuration Cluster Replication

      options.hbase_site['hbase.replication'] ?= 'true' if options.replicated_clusters

## Configuration Quota

      options.hbase_site['hbase.quota.enabled'] ?= 'false'
      options.hbase_site['hbase.quota.refresh.period'] ?= 300000

## Configuration for Log4J

      options.log4j = merge service.deps.log4j?.options, options.log4j
      options.log4j.properties ?= {}
      options.opts.java_properties['hbase.security.log.file'] ?= 'SecurityAuth-master.audit'
      #HBase bin script use directly environment bariables
      options.env['HBASE_ROOT_LOGGER'] ?= 'INFO,RFA'
      options.env['HBASE_SECURITY_LOGGER'] ?= 'INFO,RFAS'
      if options.log4j.remote_host? and options.log4j.remote_port?
        # adding SOCKET appender
        options.log4j.socket_client ?= "SOCKET"
        # Root logger
        if options.env['HBASE_ROOT_LOGGER'].indexOf(options.log4j.socket_client) is -1
        then options.env['HBASE_ROOT_LOGGER'] += ",#{options.log4j.socket_client}"
        # Security Logger
        if options.env['HBASE_SECURITY_LOGGER'].indexOf(options.log4j.socket_client) is -1
        then options.env['HBASE_SECURITY_LOGGER']+= ",#{options.log4j.socket_client}"

        options.opts.java_properties['hbase.log.application'] = 'hbase-master'
        options.opts.java_properties['hbase.log.remote_host'] = options.log4j.remote_host
        options.opts.java_properties['hbase.log.remote_port'] = options.log4j.remote_port

        options.log4j.socket_opts ?=
          Application: '${hbase.log.application}'
          RemoteHost: '${hbase.log.remote_host}'
          Port: '${hbase.log.remote_port}'
          ReconnectionDelay: '10000'

        options.log4j.properties = merge options.log4j.properties, appender
          type: 'org.apache.log4j.net.SocketAppender'
          name: options.log4j.socket_client
          logj4: options.log4j.properties
          properties: options.log4j.socket_opts

## Configuration for metrics

Configuration of HBase metrics system.

The File sink is activated by default. The Ganglia and Graphite sinks are
automatically activated if the "@rybajs/metal/retired/ganglia/collecto" and
"@rybajs/metal/graphite/collector" are respectively registered on one of the nodes of the
cluster. You can disable any of those sinks by setting its class to "false", here
how:

```json
{ "ryba": { hbase: {"metrics":
  "*.sink.file.class": false,
  "*.sink.ganglia.class": false,
  "*.sink.graphite.class": false
 } } }
```

Metrics can be filtered by context (in this exemple "master", "regionserver",
"jvm" and "ugi"). The list of available contexts can be obtained from HTTP, read
the [HBase documentation](http://hbase.apache.org/book.html#_hbase_metrics) for
additionnal informations.

```json
{ "ryba": { hbase: {"metrics":
  "hbase.sink.file-all.filename": "hbase-metrics-all.out",
  "hbase.sink.file-master.filename": "hbase-metrics-master.out",
  "hbase.sink.file-master.context": "mastert",
  "hbase.sink.file-regionserver.filename": "hbase-metrics-regionserver.outt",
  "hbase.sink.file-regionserver.context": "regionservert",
  "hbase.sink.file-jvm.filename": "hbase-metrics-jvm.outt",
  "hbase.sink.file-jvm.context": "jvmt",
  "hbase.sink.file-ugi.filename": "hbase-metrics-ugi.outt",
  "hbase.sink.file-ugi.context": "ugit"
 } } }
```

According to the default "hadoop-metrics-hbase.properties", the list of
supported contexts are "hbase", "jvm" and "rpc".

      options.metrics = merge service.deps.metrics?.options, options.metrics
      options.metrics.sinks ?= {}
      options.metrics.sinks.file_enabled ?= true
      options.metrics.sinks.ganglia_enbaled ?= !!service.deps.ganglia_collector
      options.metrics.sinks.graphite_enabled ?= false
      options.metrics.config ?= {}
      options.metrics.config['*.period'] ?= '60'
      options.metrics.config['*.source.filter.class'] ?= 'org.apache.hadoop.metrics2.filter.GlobFilter'
      options.metrics.config['hbase.*.source.filter.exclude'] ?= '*Regions*|*Namespace*|*User*'
      options.metrics.config['hbase.extendedperiod'] ?= '3600'
      # File sink
      if options.metrics.sinks.file_enabled
        options.metrics.config["*.sink.file.#{k}"] ?= v for k, v of options.metrics.sinks.file.config if service.deps.metrics?.options?.sinks?.file_enabled
        options.metrics.config['hbase.sink.file.filename'] ?= 'hbase-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if options.metrics.sinks.ganglia_enbaled
        options.metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of options.metrics.sinks.ganglia.config
        options.metrics.config['hbase.sink.ganglia.class'] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
        options.metrics.config['jvm.sink.ganglia.class'] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
        options.metrics.config['rpm.sink.ganglia.class'] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
        options.metrics.config['hbase.sink.ganglia.servers'] ?= "#{service.deps.ganglia_collector.node.fqdn}:#{service.deps.ganglia_collector.options.nn_port}"
        options.metrics.config['jvm.sink.ganglia.servers'] ?= "#{service.deps.ganglia_collector.node.fqdn}:#{service.deps.ganglia_collector.options.nn_port}"
        options.metrics.config['rpc.sink.ganglia.servers'] ?= "#{service.deps.ganglia_collector.node.fqdn}:#{service.deps.ganglia_collector.options.nn_port}"
      # Graphite sink
      if options.metrics.sinks.graphite_enabled
        throw Error 'Missing remote_host ryba.hbase.master.metrics.sinks.graphite.config.server_host' unless options.metrics.sinks.graphite.config.server_host?
        throw Error 'Missing remote_port ryba.hbase.master.metrics.sinks.graphite.config.server_port' unless options.metrics.sinks.graphite.config.server_port?
        options.metrics.config['*.sink.graphite.metrics_prefix'] ?= if options.metrics.sinks.graphite.config.metrics_prefix? then "#{options.metrics.sinks.graphite.config.metrics_prefix}.hbase" else "hbase"
        options.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of options.metrics.sinks.graphite.config if service.deps.metrics?.options?.sinks?.graphite_enabled
        options.metrics.config['hbase.sink.graphite.class'] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config['jvm.sink.graphite.class'] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config['rpc.sink.graphite.class'] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait_hdfs_nn = service.deps.hdfs_nn[0].options.wait
      for srv in service.deps.hbase_master
        srv.options.master_site ?= {}
        srv.options.master_site['hbase.master.port'] ?= '60000'
        srv.options.master_site['hbase.master.info.port'] ?= '60010'
      options.wait = {}
      options.wait.rpc = for srv in service.deps.hbase_master
        host: srv.node.fqdn
        port: srv.options.master_site['hbase.master.port']
      options.wait.http = for srv in service.deps.hbase_master
        host: srv.node.fqdn
        port: srv.options.master_site['hbase.master.info.port']

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'mixme'

## Resources

*   [Tuning G1GC For Your HBase Cluster](https://blogs.apache.org/hbase/entry/tuning_g1gc_for_your_hbase)
*   [HBase: Performance Tunners (read optimization)](http://labs.ericsson.com/blog/hbase-performance-tuners)
*   [Scanning in HBase (read optimization)](http://hadoop-hbase.blogspot.com/2012/01/scanning-in-hbase.html)
*   [Configuring HBase Memstore (write optimization)](http://blog.sematext.com/2012/17/16/hbase-memstore-what-you-should-know/)
*   [Visualizing HBase Flushes and Compactions (write optimization)](http://www.ngdata.com/visiualizing-hbase-flushes-and-compactions/)

[SecureBulkLoadEndpoint]: http://hbase.apache.org/apidocs/org/apache/hadoop/hbase/security/access/SecureBulkLoadEndpoint.html
