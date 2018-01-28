
## Configuration

Look at the file [DFSConfigKeys.java][keys] for an exhaustive list of supported
properties.

*   `site` (object)
    Properties added to the "hdfs-site.xml" file.
*   `opts` (string)
    NameNode options.

Example:

```json
{
  "ryba": {
    "hdfs": 
      "nn": {
        "java_opts": "-Xms1024m -Xmx1024m",
        "include": ["in.my.cluster"],
        "exclude": "not.in.my.cluster"
    }
  }
}
```

    module.exports = (service) ->
      options = service.options

## Identities

      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.deps.hadoop_core.options.hdfs.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.hdfs.user, options.user

## Environment

      # Layout
      options.pid_dir ?= service.deps.hadoop_core.options.hdfs.pid_dir
      options.log_dir ?= service.deps.hadoop_core.options.hdfs.log_dir
      options.conf_dir ?= '/etc/hadoop-hdfs-namenode/conf'
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.hadoop_opts ?= service.deps.hadoop_core.options.hadoop_opts
      options.hadoop_namenode_init_heap ?= '-Xms1024m'
      options.heapsize ?= '1024m'
      options.newsize ?= '200m'
      options.java_opts ?= ""
      options.hadoop_heap ?= service.deps.hadoop_core.options.hadoop_heap
      # Misc
      options.clean_logs ?= false
      options.fqdn ?= service.node.fqdn
      options.hostname ?= service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.hadoop_policy ?= {}
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

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

      # Hadoop core-site.xml
      options.core_site = merge {}, service.deps.hadoop_core.options.core_site, options.core_site or {}
      # Number of minutes after which the checkpoint gets deleted
      options.core_site['fs.trash.interval'] ?= '10080' #1 week
      # Hadoop hdfs-site.xml
      options.hdfs_site ?= {}
      options.hdfs_site['dfs.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Data
      # Comma separated list of paths. Use the list of directories.
      # For example, /data/1/hdfs/nn,/data/2/hdfs/nn.
      options.hdfs_site['dfs.namenode.name.dir'] ?= ['file:///var/hdfs/name']
      options.hdfs_site['dfs.namenode.name.dir'] = options.hdfs_site['dfs.namenode.name.dir'].join ',' if Array.isArray options.hdfs_site['dfs.namenode.name.dir']
      # Network
      options.slaves = service.deps.hdfs_dn.map (srv) -> srv.node.fqdn
      options.hdfs_site['dfs.hosts'] ?= "#{options.conf_dir}/dfs.include"
      options.include ?= service.deps.hdfs_dn.map (srv) -> srv.node.fqdn
      options.include = string.lines options.include if typeof options.include is 'string'
      options.hdfs_site['dfs.hosts.exclude'] ?= "#{options.conf_dir}/dfs.exclude"
      options.exclude ?= []
      options.exclude = string.lines options.exclude if typeof options.exclude is 'string'
      options.hdfs_site['fs.permissions.umask-mode'] ?= '026' # 0750
      # If "true", access tokens are used as capabilities
      # for accessing datanodes. If "false", no access tokens are checked on
      # accessing datanodes.
      options.hdfs_site['dfs.block.access.token.enable'] ?= if options.core_site['hadoop.security.authentication'] is 'kerberos' then 'true' else 'false'
      options.hdfs_site['dfs.block.local-path-access.user'] ?= ''
      options.hdfs_site['dfs.namenode.safemode.threshold-pct'] ?= '0.99'
      # Fix HDP Companion File bug
      options.hdfs_site['dfs.https.namenode.https-address'] = null
      # Activate ACLs
      options.hdfs_site['dfs.namenode.acls.enabled'] ?= 'true'
      options.hdfs_site['dfs.namenode.accesstime.precision'] ?= null

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Configuration in "hdfs-site.xml"
      options.hdfs_site['dfs.namenode.kerberos.principal'] ?= "nn/_HOST@#{options.krb5.realm}"
      options.hdfs_site['dfs.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      options.hdfs_site['dfs.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      options.hdfs_site['dfs.namenode.kerberos.https.principal'] = "HTTP/_HOST@#{options.krb5.realm}"
      options.hdfs_site['dfs.web.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      options.hdfs_site['dfs.web.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'

## Configuration for HDFS High Availability (HA)

Add High Availability specific properties to the "hdfs-site.xml" file. The
inserted properties are similar than the ones for a client or slave
configuration with the additionnal "dfs.namenode.shared.edits.dir" property.

The default configuration implement the "sshfence" fencing method. This method
SSHes to the target node and uses fuser to kill the process listening on the
service's TCP port.

      # HDFS Single Node configuration
      if service.instances.length is 1
        options.core_site['fs.defaultFS'] ?= "hdfs://#{service.node.fqdn}:8020"
        options.hdfs_site['dfs.ha.automatic-failover.enabled'] ?= 'false'
        options.hdfs_site['dfs.namenode.http-address'] ?= '0.0.0.0:50070'
        options.hdfs_site['dfs.namenode.https-address'] ?= '0.0.0.0:50470'
        options.hdfs_site['dfs.nameservices'] = null
      # HDFS HA configuration
      else if service.instances.length is 2
        throw Error "Required Option: options.nameservice" unless options.nameservice
        options.hdfs_site['dfs.nameservices'] ?= ''
        options.hdfs_site['dfs.nameservices'] += "#{options.nameservice} " unless options.nameservice in options.hdfs_site['dfs.nameservices'].split ' '
        options.core_site['fs.defaultFS'] ?= "hdfs://#{options.nameservice}"
        options.active_nn_host ?= service.instances[0].node.fqdn
        options.standby_nn_host = service.instances.filter( (instance) -> instance.node.fqdn isnt options.active_nn_host )[0].node.fqdn
        for srv in service.deps.hdfs_nn
          srv.options.hostname ?= srv.node.hostname
        for srv in service.deps.hdfs_jn
          options.hdfs_site['dfs.journalnode.kerberos.principal'] ?= srv.options.hdfs_site['dfs.journalnode.kerberos.principal']
      else throw Error "Invalid number of NanodeNodes, got #{service.instances.length}, expecting 2"

Since [HDFS-6376](https://issues.apache.org/jira/browse/HDFS-6376), 
Nameservice must be explicitely set as internal to provide other nameservices, 
for distcp purpose.

      options.hdfs_site['dfs.internal.nameservices'] ?= ''
      if options.nameservice not in options.hdfs_site['dfs.internal.nameservices'].split ','
        options.hdfs_site['dfs.internal.nameservices'] += "#{if options.hdfs_site['dfs.internal.nameservices'] isnt '' then ',' else ''}#{options.nameservice}" 
      options.hdfs_site["dfs.ha.namenodes.#{options.nameservice}"] = (for srv in service.deps.hdfs_nn then srv.options.hostname).join ','
      for srv in service.deps.hdfs_nn
        options.hdfs_site['dfs.namenode.http-address'] = null
        options.hdfs_site['dfs.namenode.https-address'] = null
        options.hdfs_site["dfs.namenode.rpc-address.#{options.nameservice}.#{srv.options.hostname}"] ?= "#{srv.node.fqdn}:8020"
        options.hdfs_site["dfs.namenode.http-address.#{options.nameservice}.#{srv.options.hostname}"] ?= "#{srv.node.fqdn}:50070"
        options.hdfs_site["dfs.namenode.https-address.#{options.nameservice}.#{srv.options.hostname}"] ?= "#{srv.node.fqdn}:50470"
        options.hdfs_site["dfs.client.failover.proxy.provider.#{options.nameservice}"] ?= 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
      options.hdfs_site['dfs.ha.automatic-failover.enabled'] ?= 'true'
      options.hdfs_site['dfs.namenode.shared.edits.dir'] = (for srv in service.deps.hdfs_jn then "#{srv.node.fqdn}:#{srv.options.hdfs_site['dfs.journalnode.rpc-address'].split(':')[1]}").join ';'
      options.hdfs_site['dfs.namenode.shared.edits.dir'] = "qjournal://#{options.hdfs_site['dfs.namenode.shared.edits.dir']}/#{options.nameservice}"

## SSL

      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl
      options.ssl_server = merge {}, service.deps.hadoop_core.options.ssl_server, options.ssl_server or {},
        'ssl.server.keystore.location': "#{options.conf_dir}/keystore"
        'ssl.server.truststore.location': "#{options.conf_dir}/truststore"
      options.ssl_client = merge {}, service.deps.hadoop_core.options.ssl_client, options.ssl_client or {},
        'ssl.client.truststore.location': "#{options.conf_dir}/truststore"

# ### Fencing
# 
# To prevent split-brain scenario, in addition to the Journal Quorum Process for
# write, sshfence allow ssh connection to the previous disfunctioning active
# namenode from the new one to "shoot it in the head" (STONITH).
# 
# If the previous master machine is dead, ssh connection will fail, so another
# fencing method should be configured to not block failover.
# 
#       options.hdfs_site['dfs.ha.fencing.methods'] ?= """
#       sshfence(#{options.user.name})
#       shell(/bin/true)
#       """
#       options.hdfs_site['dfs.ha.fencing.ssh.connect-timeout'] ?= '30000'
#       options.hdfs_site['dfs.ha.fencing.ssh.private-key-files'] ?= "#{options.user.home}/.ssh/id_rsa"

## Metrics

      options.metrics = merge {}, service.deps.metrics?.options, options.metrics

      options.metrics.config ?= {}
      options.metrics.sinks ?= {}
      options.metrics.sinks.file_enabled ?= true
      options.metrics.sinks.ganglia_enabled ?= false
      options.metrics.sinks.graphite_enabled ?= false
      # File sink
      if options.metrics.sinks.file_enabled
        options.metrics.config["namenode.sink.file.class"] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        options.metrics.config["*.sink.file.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.file.config if service.deps.metrics?.options?.sinks?.file_enabled
        options.metrics.config['namenode.sink.file.filename'] ?= 'namenode-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if options.metrics.sinks.ganglia_enabled
        options.metrics.config["namenode.sink.ganglia.class"] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
        options.metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of options.sinks.ganglia.config if service.deps.metrics?.options?.sinks?.ganglia_enabled
      # Graphite Sink
      if options.metrics.sinks.graphite_enabled
        throw Error 'Missing remote_host ryba.hdfs.nn.metrics.sinks.graphite.config.server_host' unless options.metrics.sinks.graphite.config.server_host?
        throw Error 'Missing remote_port ryba.hdfs.nn.metrics.sinks.graphite.config.server_port' unless options.metrics.sinks.graphite.config.server_port?
        options.metrics.config["namenode.sink.graphite.class"] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.graphite.config if service.deps.metrics?.options?.sinks?.graphite_enabled

## Log4J
Inherits log4j configuration from the `ryba/log4j`. The rendered file uses the variable
`options.log4j.properties`

      options.log4j = merge {}, service.deps.log4j?.options, options.log4j
      options.log4j.properties ?= {}
      options.log4j.root_logger ?= 'INFO,RFA'
      options.log4j.security_logger ?= 'INFO,DRFAS'
      options.log4j.audit_logger ?= 'INFO,RFAAUDIT'
      # adding SOCKET appender
      if options.log4j.remote_host? andoptions.log4j.remote_port?
        options.log4j.socket_client ?= "SOCKET"
        # Root logger
        if options.log4j.root_logger.indexOf(options.log4j.socket_client) is -1
        then options.log4j.root_logger += ",#{options.log4j.socket_client}"
        # Security Logger
        if options.log4j.security_logger.indexOf(options.log4j.socket_client) is -1
        then options.log4j.security_logger += ",#{options.log4j.socket_client}"
        # Audit Logger
        if options.log4j.audit_logger.indexOf(options.log4j.socket_client) is -1
        then options.log4j.audit_logger += ",#{options.log4j.socket_client}"
        # Adding Application name, remote host and port values in namenode's opts
        options.opts['hadoop.log.application'] ?= 'namenode'
        options.opts['hadoop.log.remote_host'] ?= options.log4j.remote_host
        options.opts['hadoop.log.remote_port'] ?= options.log4j.remote_port
        options.log4j.socket_opts ?=
          Application: '${hadoop.log.application}'
          RemoteHost: '${hadoop.log.remote_host}'
          Port: '${hadoop.log.remote_port}'
          ReconnectionDelay: '10000'
        options.log4j.properties = merge options.log4j.properties, appender
          type: 'org.apache.log4j.net.SocketAppender'
          name: options.log4j.socket_client
          logj4: options.log4j.properties
          properties: options.log4j.socket_opts

## Export configuration

      for srv in service.deps.hdfs_dn
        for property in [
          'dfs.namenode.kerberos.principal'
          'dfs.namenode.kerberos.internal.spnego.principal'
          'dfs.namenode.kerberos.https.principal'
          'dfs.web.authentication.kerberos.principal'
          'dfs.ha.automatic-failover.enabled'
          'dfs.nameservices'
          'dfs.internal.nameservices'
          'fs.permissions.umask-mode'
          'dfs.block.access.token.enable'
        ] then srv.options.hdfs_site[property] ?= options.hdfs_site[property]
        for property in [
          'fs.defaultFS'
        ] then srv.options.core_site[property] ?= options.core_site[property]
        for property of options.hdfs_site
          ok = false
          ok = true if /^dfs\.namenode\.\w+-address/.test property
          ok = true if property.indexOf('dfs.ha.namenodes.') is 0
          continue unless ok
          srv.options.hdfs_site[property] = options.hdfs_site[property]

      for srv in service.deps.hdfs_jn
        for property in [
          'dfs.namenode.kerberos.principal'
          'dfs.nameservices'
          'dfs.internal.nameservices'
          'fs.permissions.umask-mode'
          'dfs.block.access.token.enable'
        ] then srv.options.hdfs_site[property] ?= options.hdfs_site[property]
        for property in [
          'fs.defaultFS'
        ] then srv.options.core_site[property] ?= options.core_site[property]
        for property of options.hdfs_site
          ok = false
          ok = true if /^dfs\.namenode\.\w+-address/.test property
          ok = true if property.indexOf('dfs.ha.namenodes.') is 0
          continue unless ok
          srv.options.hdfs_site[property] = options.hdfs_site[property]

## Test

      options.test = merge {}, service.deps.test_user.options, options.test or {}

## Wait

      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait_hdfs_jn = service.deps.hdfs_jn[0].options.wait
      options.wait_hdfs_dn = service.deps.hdfs_dn[0].options.wait
      options.wait = {}
      options.wait.conf_dir = options.conf_dir
      options.wait.ipc = for srv in service.deps.hdfs_nn
        nameservice =  if options.nameservice then ".#{options.nameservice}" or ''
        hostname = if options.nameservice then ".#{srv.node.hostname}" else ''
        if srv.options.hdfs_site["dfs.namenode.rpc-address#{nameservice}#{hostname}"]
         [fqdn, port] = srv.options.hdfs_site["dfs.namenode.rpc-address#{nameservice}#{hostname}"].split(':')
        else 
          fqdn = srv.node.fqdn
          port = 8020
        host: fqdn, port: port
      options.wait.http = for srv in service.deps.hdfs_nn
        protocol = if options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        nameservice =  if options.nameservice then ".#{options.nameservice}" or ''
        hostname = if options.nameservice then ".#{srv.node.hostname}" else ''
        if srv.options.hdfs_site["dfs.namenode.rpc-address#{nameservice}#{hostname}"]
          [fqdn, port] = srv.options.hdfs_site["dfs.namenode.#{protocol}-address#{nameservice}#{hostname}"].split(':')
        else 
          fqdn = srv.node.fqdn
          port = if options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then '50070' else '50470'
        host: fqdn, port: port
      options.wait.krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## Dependencies

    string = require 'nikita/lib/misc/string'
    {merge} = require 'nikita/lib/misc'
    appender = require '../../lib/appender'
