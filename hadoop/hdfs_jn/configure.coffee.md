
# Hadoop HDFS JournalNode Configure

The JournalNode uses properties define inside the "ryba/hadoop/hdfs" module. It
also declare a new property "dfs.journalnode.edits.dir".

*   `hdp.hdfs.site['dfs.journalnode.edits.dir']` (string)   
    The directory where the JournalNode will write transaction logs, default
    to "/var/run/hadoop-hdfs/journalnode\_edit\_dir"

Example:

```json
{
  "site": {
    "dfs.journalnode.edits.dir": "/var/run/hadoop-hdfs/journalnode\_edit\_dir"
  }
}
```

    module.exports = (service) ->
      options = service.options

## Environment

      options.pid_dir ?= service.deps.hadoop_core.options.hdfs.pid_dir
      options.log_dir ?= service.deps.hadoop_core.options.hdfs.log_dir
      options.conf_dir ?= '/etc/hadoop-hdfs-journalnode/conf'
      options.hadoop_opts ?= service.deps.hadoop_core.options.hadoop_opts
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.hadoop_heap ?= service.deps.hadoop_core.options.hadoop_heap
      options.newsize ?= '200m'
      options.heapsize ?= '1024m'
      # Misc
      options.clean_logs ?= false
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.fqdn = service.node.fqdn
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## Identities

      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.deps.hadoop_core.options.hdfs.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.hdfs.user, options.user

## System Options

      options.opts ?= {}
      options.opts.base ?= ''
      options.opts.java_properties ?= {}
      options.opts.jvm ?= {}
      options.opts.jvm['-Xms'] ?= options.heapsize
      options.opts.jvm['-Xmx'] ?= options.heapsize
      options.opts.jvm['-XX:NewSize='] ?= options.newsize #should be 1/8 of datanode heapsize
      options.opts.jvm['-XX:MaxNewSize='] ?= options.newsize #should be 1/8 of datanode heapsize

## Configuration

      options.core_site = merge {}, service.deps.hadoop_core.options.core_site, options.core_site or {}
      options.hdfs_site ?= {}
      options.hdfs_site['dfs.journalnode.rpc-address'] ?= '0.0.0.0:8485'
      options.hdfs_site['dfs.journalnode.http-address'] ?= '0.0.0.0:8480'
      options.hdfs_site['dfs.journalnode.https-address'] ?= '0.0.0.0:8481'
      options.hdfs_site['dfs.http.policy'] ?= 'HTTPS_ONLY'
      # Recommandation is to ideally have dedicated disks to optimize fsyncs operation
      options.hdfs_site['dfs.journalnode.edits.dir'] = options.hdfs_site['dfs.journalnode.edits.dir'].join ',' if Array.isArray options.hdfs_site['dfs.journalnode.edits.dir']
      # options.hdfs_site['dfs.journalnode.edits.dir'] ?= ['/var/hdfs/edits']
      throw Error "Required Option \"hdfs_site['dfs.journalnode.edits.dir']\": got #{JSON.stringify options.hdfs_site['dfs.journalnode.edits.dir']}" unless options.hdfs_site['dfs.journalnode.edits.dir']

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      # options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Kerberos
      # TODO: Principal should be "jn/{host}@{realm}", however, there is
      # no properties to have a separated keytab between jn and spnego principals
      options.hdfs_site['dfs.journalnode.kerberos.internal.spnego.principal'] = "HTTP/_HOST@#{options.krb5.realm }"
      options.hdfs_site['dfs.journalnode.kerberos.principal'] = "HTTP/_HOST@#{options.krb5.realm }"
      options.hdfs_site['dfs.journalnode.keytab.file'] = '/etc/security/keytabs/spnego.service.keytab'

## SSL

      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl
      options.ssl_server = merge {}, service.deps.hadoop_core.options.ssl_server, options.ssl_server or {}
      options.ssl_client = merge {}, service.deps.hadoop_core.options.ssl_client, options.ssl_client or {}

## Metrics

      options.metrics = merge {}, service.deps.metrics?.options, options.metrics

      options.metrics.config ?= {}
      options.metrics.config["*.period"] ?= '60'
      options.metrics.sinks ?= {}
      options.metrics.sinks.file_enabled ?= true
      options.metrics.sinks.ganglia_enabled ?= false
      options.metrics.sinks.graphite_enabled ?= false
      # File sink
      if options.metrics.sinks.file_enabled
        options.metrics.config["*.sink.file.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.file.config if service.deps.metrics?.options?.sinks?.file_enabled
        options.metrics.config["journalnode.sink.file.class"] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        options.metrics.config['journalnode.sink.file.filename'] ?= 'journalnode-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if options.metrics.sinks.ganglia_enabled
        options.metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of options.sinks.ganglia.config if service.deps.metrics?.options?.sinks?.ganglia_enabled
        options.metrics.config["journalnode.sink.ganglia.class"] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
      # Graphite Sink
      if options.metrics.sinks.graphite_enabled
        throw Error 'Missing remote_host ryba.hdfs.jn.metrics.sinks.graphite.config.server_host' unless options.metrics.sinks.graphite.config.server_host?
        throw Error 'Missing remote_port ryba.hdfs.jn.metrics.sinks.graphite.config.server_port' unless options.metrics.sinks.graphite.config.server_port?
        options.metrics.config["journalnode.sink.graphite.class"] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.graphite.config if service.deps.metrics?.options?.sinks?.graphite_enabled

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait = {}
      options.wait.rpc = for srv in service.deps.hdfs_jn
        srv.options.hdfs_site ?= {}
        srv.options.hdfs_site['dfs.journalnode.rpc-address'] ?= '0.0.0.0:8485'
        [_, port] = srv.options.hdfs_site['dfs.journalnode.rpc-address'].split ':'
        host: srv.node.fqdn, port: port
      options.wait.http = for srv in service.deps.hdfs_jn
        srv.options.hdfs_site ?= {}
        policy = srv.options.hdfs_site['dfs.http.policy'] or options.hdfs_site['dfs.http.policy']
        address = if policy is 'HTTP_ONLY'
        then srv.options.hdfs_site['dfs.journalnode.http-address'] or '0.0.0.0:8480'
        else srv.options.hdfs_site['dfs.journalnode.https-address'] or '0.0.0.0:8481'
        [_, port] = address.split ':'
        host: srv.node.fqdn, port: port

## Dependencies

    {merge} = require 'nikita/lib/misc'
