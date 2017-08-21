
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

    module.exports = ->
      service = migration.call @, service, 'ryba/hadoop/hdfs_nn', ['ryba', 'hdfs', 'nn'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        zookeeper_server: key: ['ryba', 'zookeeper']
        hadoop_core: key: ['ryba']
        hdfs_jn: key: ['ryba', 'hdfs', 'jn']
        hdfs_dn: key: ['ryba', 'hdfs', 'dn']
        hdfs_nn: key: ['ryba', 'hdfs', 'nn']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
      @config.ryba ?= {}
      @config.ryba.hdfs ?= {}
      @config.ryba.hdfs.nn ?= {}
      options = @config.ryba.hdfs.nn = service.options

## Identities

      options.hadoop_group ?= merge {}, service.use.hadoop_core.options.hadoop_group, options.hadoop_group or {}
      options.group ?= merge {}, service.use.hadoop_core.options.hdfs.group, options.group or {}
      options.user ?= merge {}, service.use.hadoop_core.options.hdfs.user, options.user or {}

## Environment

      # Layout
      options.pid_dir ?= service.use.hadoop_core.options.hdfs.pid_dir
      options.log_dir ?= service.use.hadoop_core.options.hdfs.log_dir
      options.conf_dir ?= '/etc/hadoop-hdfs-namenode/conf'
      # Java
      options.java_home ?= service.use.java.options.java_home
      options.hadoop_opts ?= service.use.hadoop_core.options.hadoop_opts
      options.hadoop_namenode_init_heap ?= '-Xms1024m'
      options.heapsize ?= '1024m'
      options.newsize ?= '200m'
      options.java_opts ?= ""
      options.hadoop_heap ?= service.use.hadoop_core.options.hadoop_heap
      # Misc
      options.clean_logs ?= false
      options.fqdn ?= service.node.fqdn
      options.hostname ?= service.node.hostname
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      options.hadoop_policy ?= {}

## Namenode Java Options

      # opts will be rendered as -Dkey=value and appended to java_opts
      options.opts ?= {}

## Configuration

      # Hadoop core-site.xml
      options.core_site = merge {}, service.use.hadoop_core.options.core_site, options.core_site or {}
      # Number of minutes after which the checkpoint gets deleted
      options.core_site['fs.trash.interval'] ?= '10080' #1 week
      # Hadoop hdfs-site.xml
      options.site ?= {}
      options.site['dfs.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Data
      # Comma separated list of paths. Use the list of directories.
      # For example, /data/1/hdfs/nn,/data/2/hdfs/nn.
      options.site['dfs.namenode.name.dir'] ?= ['file:///var/hdfs/name']
      options.site['dfs.namenode.name.dir'] = options.site['dfs.namenode.name.dir'].join ',' if Array.isArray options.site['dfs.namenode.name.dir']
      # Network
      options.slaves = service.use.hdfs_dn.map (srv) -> srv.node.fqdn
      options.site['dfs.hosts'] ?= "#{options.conf_dir}/dfs.include"
      options.include ?= service.use.hdfs_dn.map (srv) -> srv.node.fqdn
      options.include = string.lines options.include if typeof options.include is 'string'
      options.site['dfs.hosts.exclude'] ?= "#{options.conf_dir}/dfs.exclude"
      options.exclude ?= []
      options.exclude = string.lines options.exclude if typeof options.exclude is 'string'
      options.site['fs.permissions.umask-mode'] ?= '026' # 0750
      # If "true", access tokens are used as capabilities
      # for accessing datanodes. If "false", no access tokens are checked on
      # accessing datanodes.
      options.site['dfs.block.access.token.enable'] ?= if options.core_site['hadoop.security.authentication'] is 'kerberos' then 'true' else 'false'
      options.site['dfs.block.local-path-access.user'] ?= ''
      options.site['dfs.namenode.safemode.threshold-pct'] ?= '0.99'
      # Fix HDP Companion File bug
      options.site['dfs.https.namenode.https-address'] = null
      # Activate ACLs
      options.site['dfs.namenode.acls.enabled'] ?= 'true'
      options.site['dfs.namenode.accesstime.precision'] ?= null

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]
      # Configuration in "hdfs-site.xml"
      options.site['dfs.namenode.kerberos.principal'] ?= "nn/_HOST@#{options.krb5.realm}"
      options.site['dfs.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      options.site['dfs.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      options.site['dfs.namenode.kerberos.https.principal'] = "HTTP/_HOST@#{options.krb5.realm}"
      options.site['dfs.web.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      options.site['dfs.web.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'

## Configuration for HDFS High Availability (HA)

Add High Availability specific properties to the "hdfs-site.xml" file. The
inserted properties are similar than the ones for a client or slave
configuration with the additionnal "dfs.namenode.shared.edits.dir" property.

The default configuration implement the "sshfence" fencing method. This method
SSHes to the target node and uses fuser to kill the process listening on the
service's TCP port.

      # HDFS Single Node configuration
      if service.nodes.length is 1
        options.core_site['fs.defaultFS'] ?= "hdfs://#{service.node.fqdn}:8020"
        options.site['dfs.ha.automatic-failover.enabled'] ?= 'false'
        options.site['dfs.namenode.http-address'] ?= '0.0.0.0:50070'
        options.site['dfs.namenode.https-address'] ?= '0.0.0.0:50470'
        options.site['dfs.nameservices'] = null
      # HDFS HA configuration
      else if service.nodes.length is 2
        throw Error "Required Option: site['dfs.nameservices']" unless options.site['dfs.nameservices']
        options.core_site['fs.defaultFS'] ?= "hdfs://#{options.site['dfs.nameservices']}"
        options.active_nn_host ?= service.nodes[0].fqdn
        options.standby_nn_host = service.nodes.filter( (node) -> node.fqdn isnt options.active_nn_host )[0].fqdn
        for srv in service.use.hdfs_nn
          srv.options.hostname ?= srv.node.hostname
        for srv in service.use.hdfs_jn
          options.site['dfs.journalnode.kerberos.principal'] ?= srv.options.site['dfs.journalnode.kerberos.principal']
      else throw Error "Invalid number of NanodeNodes, got #{service.nodes.length}, expecting 2"

Since [HDFS-6376](https://issues.apache.org/jira/browse/HDFS-6376), 
Nameservice must be explicitely set as internal to provide other nameservices, 
for distcp purpose.

      options.site['dfs.internal.nameservices'] ?= options.site['dfs.nameservices']
      options.site["dfs.ha.namenodes.#{options.site['dfs.nameservices']}"] = (for srv in service.use.hdfs_nn then srv.options.hostname).join ','
      for srv in service.use.hdfs_nn
        options.site['dfs.namenode.http-address'] = null
        options.site['dfs.namenode.https-address'] = null
        options.site["dfs.namenode.rpc-address.#{options.site['dfs.nameservices']}.#{srv.options.hostname}"] ?= "#{srv.node.fqdn}:8020"
        options.site["dfs.namenode.http-address.#{options.site['dfs.nameservices']}.#{srv.options.hostname}"] ?= "#{srv.node.fqdn}:50070"
        options.site["dfs.namenode.https-address.#{options.site['dfs.nameservices']}.#{srv.options.hostname}"] ?= "#{srv.node.fqdn}:50470"
        options.site["dfs.client.failover.proxy.provider.#{options.site['dfs.nameservices']}"] ?= 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
      options.site['dfs.ha.automatic-failover.enabled'] ?= 'true'
      options.site['dfs.namenode.shared.edits.dir'] = (for srv in service.use.hdfs_jn then "#{srv.node.fqdn}:#{srv.options.site['dfs.journalnode.rpc-address'].split(':')[1]}").join ';'
      options.site['dfs.namenode.shared.edits.dir'] = "qjournal://#{options.site['dfs.namenode.shared.edits.dir']}/#{options.site['dfs.nameservices']}"

## SSL

      options.ssl = merge options.ssl or {}, service.use.hadoop_core.options.ssl
      options.ssl_server = merge service.use.hadoop_core.options.ssl_server, options.ssl_server or {},
        'ssl.server.keystore.location': "#{options.conf_dir}/keystore"
        'ssl.server.truststore.location': "#{options.conf_dir}/truststore"
      options.ssl_client = merge service.use.hadoop_core.options.ssl_client, options.ssl_client or {},
        'ssl.client.truststore.location': "#{options.conf_dir}/truststore"

### Fencing

To prevent split-brain scenario, in addition to the Journal Quorum Process for
write, sshfence allow ssh connection to the previous disfunctioning active
namenode from the new one to "shoot it in the head" (STONITH).

If the previous master machine is dead, ssh connection will fail, so another
fencing method should be configured to not block failover.

      options.site['dfs.ha.fencing.methods'] ?= """
      sshfence(#{options.user.name})
      shell(/bin/true)
      """
      options.site['dfs.ha.fencing.ssh.connect-timeout'] ?= '30000'
      options.site['dfs.ha.fencing.ssh.private-key-files'] ?= "#{options.user.home}/.ssh/id_rsa"

## Metrics

      options.hadoop_metrics ?= service.use.hadoop_core.options.hadoop_metrics

## Configuration for Log4J

      options.log4j ?= {}
      options.root_logger ?= 'INFO,RFA'
      options.security_logger ?= 'INFO,DRFAS'
      options.audit_logger ?= 'INFO,RFAAUDIT'
      # adding SOCKET appender
      if @config.log4j?.services?
        if @config.log4j?.remote_host? and @config.log4j?.remote_port? and ('ryba/hadoop/hdfs_nn' in @config.log4j?.services)
          options.socket_client ?= "SOCKET"
          # Root logger
          if options.root_logger.indexOf(options.socket_client) is -1
          then options.root_logger += ",#{options.socket_client}"
          # Security Logger
          if options.security_logger.indexOf(options.socket_client) is -1
          then options.security_logger += ",#{options.socket_client}"
          # Audit Logger
          if options.audit_logger.indexOf(options.socket_client) is -1
          then options.audit_logger += ",#{options.socket_client}"
          # Adding Application name, remote host and port values in namenode's opts
          options.opts['hadoop.log.application'] ?= 'namenode'
          options.opts['hadoop.log.remote_host'] ?= @config.log4j.remote_host
          options.opts['hadoop.log.remote_port'] ?= @config.log4j.remote_port

          options.socket_opts ?=
            Application: '${hadoop.log.application}'
            RemoteHost: '${hadoop.log.remote_host}'
            Port: '${hadoop.log.remote_port}'
            ReconnectionDelay: '10000'

          options.log4j = merge options.log4j, appender
            type: 'org.apache.log4j.net.SocketAppender'
            name: options.socket_client
            logj4: options.log4j
            properties: options.socket_opts

## Ranger

      options.ranger = true if service.use.ranger_admin

## Export configuration

      for srv in service.use.hdfs_dn
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
        ] then srv.options.site[property] ?= options.site[property]
        for property of options.site
          ok = false
          ok = true if /^dfs\.namenode\.\w+-address/.test property
          ok = true if property.indexOf('dfs.ha.namenodes.') is 0
          ok = true if property.indexOf('dfs.namenode.rpc-address.') is 0
          ok = true if property.indexOf('dfs.namenode.http-address.') is 0
          ok = true if property.indexOf('dfs.namenode.https-address.') is 0
          continue unless ok
          srv.options.site[property] = options.site[property]

## Wait

      options.wait_zookeeper_server = service.use.zookeeper_server[0].options.wait
      options.wait_hdfs_jn = service.use.hdfs_jn[0].options.wait
      options.wait_hdfs_dn = service.use.hdfs_dn[0].options.wait
      options.wait = {}
      options.wait.ipc = for srv in service.use.hdfs_nn
        nameservice =  if options.site['dfs.nameservices'] then ".#{options.site['dfs.nameservices']}" or ''
        hostname = if options.site['dfs.nameservices'] then ".#{srv.node.hostname}" else ''
        if srv.options.site["dfs.namenode.rpc-address#{nameservice}#{hostname}"]
         [fqdn, port] = srv.options.site["dfs.namenode.rpc-address#{nameservice}#{hostname}"].split(':')
        else 
          fqdn = srv.node.fqdn
          port = 8020
        host: fqdn, port: port
      options.wait.http = for srv in service.use.hdfs_nn
        protocol = if options.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        nameservice =  if options.site['dfs.nameservices'] then ".#{options.site['dfs.nameservices']}" or ''
        hostname = if options.site['dfs.nameservices'] then ".#{srv.node.hostname}" else ''
        if srv.options.site["dfs.namenode.rpc-address#{nameservice}#{hostname}"]
          [fqdn, port] = srv.options.site["dfs.namenode.#{protocol}-address#{nameservice}#{hostname}"].split(':')
        else 
          fqdn = srv.node.fqdn
          port = if options.site['dfs.http.policy'] is 'HTTP_ONLY' then '50070' else '50470'
        host: fqdn, port: port
      options.wait.krb5_user = service.use.hadoop_core.options.hdfs.krb5_user

## Dependencies

    string = require 'nikita/lib/misc/string'
    {merge} = require 'nikita/lib/misc'
    appender = require '../../lib/appender'
    migration = require 'masson/lib/migration'
