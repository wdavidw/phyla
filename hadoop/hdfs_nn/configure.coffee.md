
## Configuration

Look at the file [DFSConfigKeys.java][keys] for an exhaustive list of supported
properties.

*   `ryba.hdfs.nn.site` (object)
    Properties added to the "hdfs-site.xml" file.
*   `ryba.hdfs.namenode_opts` (string)
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
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      jn_ctxs = @contexts 'ryba/hadoop/hdfs_jn'
      dn_ctxs = @contexts 'ryba/hadoop/hdfs_dn'
      {ryba} = @config

## Core Site

      @config.ryba.core_site ?= {}
      @config.ryba.core_site['io.compression.codecs'] ?= "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec"
      if nn_ctxs.length is 1
        @config.ryba.core_site['fs.defaultFS'] ?= "hdfs://#{nn_ctxs[0].config.host}:8020"
      else if nn_ctxs.length is 2
        @config.ryba.core_site['fs.defaultFS'] ?= "hdfs://#{@config.ryba.nameservice}"
        @config.ryba.active_nn_host ?= nn_ctxs[0].config.host
        [standby_nn_ctxs] = nn_ctxs.filter( (nn_ctx) => nn_ctx.config.host isnt @config.ryba.active_nn_host )
        @config.ryba.standby_nn_host = standby_nn_ctxs.config.host
      else throw Error "Invalid number of NanodeNodes, got #{nn_ctxs.length}, expecting 2"

## Environment

      ryba.hdfs.nn ?= {}
      ryba.hdfs.nn.conf_dir ?= '/etc/hadoop-hdfs-namenode/conf'
      ryba.hdfs.nn.core_site ?= {}
      #Number of minutes after which the checkpoint gets deleted
      ryba.hdfs.nn.core_site['fs.trash.interval'] ?= '10080' #1 week
      ryba.hdfs.nn.site ?= {}
      ryba.hdfs.nn.site['dfs.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # throw Error "Missing \"ryba.zkfc_password\" property" unless ryba.zkfc_password
      # Data
      # Comma separated list of paths. Use the list of directories.
      # For example, /data/1/hdfs/nn,/data/2/hdfs/nn.
      ryba.hdfs.nn.site['dfs.namenode.name.dir'] ?= ['file:///var/hdfs/name']
      ryba.hdfs.nn.site['dfs.namenode.name.dir'] = ryba.hdfs.nn.site['dfs.namenode.name.dir'].join ',' if Array.isArray ryba.hdfs.nn.site['dfs.namenode.name.dir']
      # Network
      ryba.hdfs.nn.site['dfs.hosts'] ?= "#{ryba.hdfs.nn.conf_dir}/dfs.include"
      ryba.hdfs.include ?= dn_ctxs.map (context) -> context.config.host
      ryba.hdfs.include = string.lines ryba.hdfs.include if typeof ryba.hdfs.include is 'string'
      ryba.hdfs.nn.site['dfs.hosts.exclude'] ?= "#{ryba.hdfs.nn.conf_dir}/dfs.exclude"
      ryba.hdfs.exclude ?= []
      ryba.hdfs.exclude = string.lines ryba.hdfs.exclude if typeof ryba.hdfs.exclude is 'string'
      ryba.hdfs.nn.heapsize ?= '1024m'
      ryba.hdfs.nn.newsize ?= '200m'
      ryba.hdfs.nn.site['fs.permissions.umask-mode'] ?= '026' # 0750
      # If "true", access tokens are used as capabilities
      # for accessing datanodes. If "false", no access tokens are checked on
      # accessing datanodes.
      ryba.hdfs.nn.site['dfs.block.access.token.enable'] ?= if ryba.core_site['hadoop.security.authentication'] is 'kerberos' then 'true' else 'false'
      ryba.hdfs.nn.site['dfs.block.local-path-access.user'] ?= ''
      ryba.hdfs.nn.site['dfs.namenode.safemode.threshold-pct'] ?= '0.99'
      # Kerberos
      ryba.hdfs.nn.site['dfs.namenode.kerberos.principal'] ?= "nn/_HOST@#{ryba.realm}"
      ryba.hdfs.nn.site['dfs.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      ryba.hdfs.nn.site['dfs.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{ryba.realm}"
      ryba.hdfs.nn.site['dfs.namenode.kerberos.https.principal'] = "HTTP/_HOST@#{ryba.realm}"
      ryba.hdfs.nn.site['dfs.web.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{ryba.realm}"
      ryba.hdfs.nn.site['dfs.web.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      # Fix HDP Companion File bug
      ryba.hdfs.nn.site['dfs.https.namenode.https-address'] = null
      # Activate ACLs
      ryba.hdfs.nn.site['dfs.namenode.acls.enabled'] ?= 'true'
      ryba.hdfs.nn.site['dfs.namenode.accesstime.precision'] ?= null

## SSL

      ryba.hdfs.nn.ssl_client = merge ryba.hdfs.nn.ssl_client, ryba.ssl_client,
        'ssl.client.truststore.location': "#{ryba.hdfs.nn.conf_dir}/truststore"
      ryba.hdfs.nn.ssl_server = merge ryba.hdfs.nn.ssl_server, ryba.ssl_server,
        'ssl.server.keystore.location': "#{ryba.hdfs.nn.conf_dir}/keystore"
        'ssl.server.truststore.location': "#{ryba.hdfs.nn.conf_dir}/truststore"

## Configuration for HDFS High Availability (HA)

Add High Availability specific properties to the "hdfs-site.xml" file. The
inserted properties are similar than the ones for a client or slave
configuration with the additionnal "dfs.namenode.shared.edits.dir" property.

The default configuration implement the "sshfence" fencing method. This method
SSHes to the target node and uses fuser to kill the process listening on the
service's TCP port.

      if nn_ctxs.length is 1
        ryba.hdfs.nn.site['dfs.ha.automatic-failover.enabled'] ?= 'false'
        ryba.hdfs.nn.site['dfs.namenode.http-address'] ?= '0.0.0.0:50070'
        ryba.hdfs.nn.site['dfs.namenode.https-address'] ?= '0.0.0.0:50470'
      else
        # HDFS HA configuration
        for nn_ctx in nn_ctxs
          nn_ctx.config.shortname ?= nn_ctx.config.host.split('.')[0]
        for jn_ctx in jn_ctxs
          ryba.hdfs.nn.site['dfs.journalnode.kerberos.principal'] ?= jn_ctx.config.ryba.hdfs.site['dfs.journalnode.kerberos.principal']
        ryba.hdfs.nn.site['dfs.nameservices'] = ryba.nameservice

Since [HDFS-6376](https://issues.apache.org/jira/browse/HDFS-6376), 
Nameservice must be explicitely set as internal to provide other nameservices, 
for distcp purpose.

        ryba.hdfs.nn.site['dfs.internal.nameservices'] ?= ryba.nameservice
        ryba.hdfs.nn.site["dfs.ha.namenodes.#{ryba.nameservice}"] = (for nn_ctx in nn_ctxs then nn_ctx.config.shortname).join ','
        for nn_ctx in nn_ctxs
          ryba.hdfs.nn.site['dfs.namenode.http-address'] = null
          ryba.hdfs.nn.site['dfs.namenode.https-address'] = null
          ryba.hdfs.nn.site["dfs.namenode.rpc-address.#{ryba.nameservice}.#{nn_ctx.config.shortname}"] ?= "#{nn_ctx.config.host}:8020"
          ryba.hdfs.nn.site["dfs.namenode.http-address.#{ryba.nameservice}.#{nn_ctx.config.shortname}"] ?= "#{nn_ctx.config.host}:50070"
          ryba.hdfs.nn.site["dfs.namenode.https-address.#{ryba.nameservice}.#{nn_ctx.config.shortname}"] ?= "#{nn_ctx.config.host}:50470"
        ryba.hdfs.nn.site["dfs.client.failover.proxy.provider.#{ryba.nameservice}"] ?= 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
        ryba.hdfs.nn.site['dfs.ha.automatic-failover.enabled'] ?= 'true'
        ryba.hdfs.nn.site['dfs.namenode.shared.edits.dir'] = (for jn_ctx in jn_ctxs then "#{jn_ctx.config.host}:8485").join ';'
        ryba.hdfs.nn.site['dfs.namenode.shared.edits.dir'] = "qjournal://#{ryba.hdfs.nn.site['dfs.namenode.shared.edits.dir']}/#{ryba.hdfs.nn.site['dfs.nameservices']}"


### Fencing

To prevent split-brain scenario, in addition to the Journal Quorum Process for
write, sshfence allow ssh connection to the previous disfunctioning active
namenode from the new one to "shoot it in the head" (STONITH).

If the previous master machine is dead, ssh connection will fail, so another
fencing method should be configured to not block failover.

        ryba.hdfs.nn.site['dfs.ha.fencing.methods'] ?= """
        sshfence(#{ryba.hdfs.user.name})
        shell(/bin/true)
        """
        ryba.hdfs.nn.site['dfs.ha.fencing.ssh.connect-timeout'] ?= '30000'
        ryba.hdfs.nn.site['dfs.ha.fencing.ssh.private-key-files'] ?= "#{ryba.hdfs.user.home}/.ssh/id_rsa"

      hdfs_ctxs = @contexts ['ryba/hadoop/hdfs_dn', 'ryba/hadoop/hdfs_snn', 'ryba/hadoop/httpfs']
      for hdfs_ctx in hdfs_ctxs
        hdfs_ctx.config ?= {}
        hdfs_ctx.config.ryba.hdfs ?= {}
        hdfs_ctx.config.ryba.hdfs.site ?= {}
        hdfs_ctx.config.ryba.hdfs.site['dfs.http.policy'] ?= @config.ryba.hdfs.nn.site['dfs.http.policy']

## Namenode JAVA Virtual Machine Options

      ryba.hdfs.nn.heapsize ?= '1024m'
      ryba.hdfs.nn.newsize ?= '200m'
      ryba.hdfs.nn.java_opts ?= ""

## Namenode Java Options

      # opts will be rendered as -Dkey=value and appended to java_opts
      ryba.hdfs.nn.opts ?= {}

## Configuration for Log4J

      ryba.hdfs.nn.log4j ?= {}
      ryba.hdfs.nn.root_logger ?= 'INFO,RFA'
      ryba.hdfs.nn.security_logger ?= 'INFO,DRFAS'
      ryba.hdfs.nn.audit_logger ?= 'INFO,RFAAUDIT'
      # adding SOCKET appender
      if @config.log4j?.services?
        if @config.log4j?.remote_host? and @config.log4j?.remote_port? and ('ryba/hadoop/hdfs_nn' in @config.log4j?.services)
          ryba.hdfs.nn.socket_client ?= "SOCKET"
          # Root logger
          if ryba.hdfs.nn.root_logger.indexOf(ryba.hdfs.nn.socket_client) is -1
          then ryba.hdfs.nn.root_logger += ",#{ryba.hdfs.nn.socket_client}"
          # Security Logger
          if ryba.hdfs.nn.security_logger.indexOf(ryba.hdfs.nn.socket_client) is -1
          then ryba.hdfs.nn.security_logger += ",#{ryba.hdfs.nn.socket_client}"
          # Audit Logger
          if ryba.hdfs.nn.audit_logger.indexOf(ryba.hdfs.nn.socket_client) is -1
          then ryba.hdfs.nn.audit_logger += ",#{ryba.hdfs.nn.socket_client}"
          # Adding Application name, remote host and port values in namenode's opts
          ryba.hdfs.nn.opts['hadoop.log.application'] ?= 'namenode'
          ryba.hdfs.nn.opts['hadoop.log.remote_host'] ?= @config.log4j.remote_host
          ryba.hdfs.nn.opts['hadoop.log.remote_port'] ?= @config.log4j.remote_port

          ryba.hdfs.nn.socket_opts ?=
            Application: '${hadoop.log.application}'
            RemoteHost: '${hadoop.log.remote_host}'
            Port: '${hadoop.log.remote_port}'
            ReconnectionDelay: '10000'

          ryba.hdfs.nn.log4j = merge ryba.hdfs.nn.log4j, appender
            type: 'org.apache.log4j.net.SocketAppender'
            name: ryba.hdfs.nn.socket_client
            logj4: ryba.hdfs.nn.log4j
            properties: ryba.hdfs.nn.socket_opts

## Export configuration

      for dn_ctx in dn_ctxs
        # dn_ctx.config ?= {}
        # dn_ctx.config.ryba.hdfs ?= {}
        # dn_ctx.config.ryba.hdfs.dn ?= {}
        # dn_ctx.config.ryba.hdfs.dn.site ?= {}
        dn_ctx.config.ryba.hdfs.dn.site['fs.permissions.umask-mode'] ?= ryba.hdfs.nn.site['fs.permissions.umask-mode']
        dn_ctx.config.ryba.hdfs.dn.site['dfs.block.access.token.enable'] ?= ryba.hdfs.nn.site['dfs.block.access.token.enable']
        
        dn_ctx.config.ryba.hdfs.dn.core_site['fs.defaultFS'] ?= @config.ryba.core_site['fs.defaultFS']

## Dependencies

    string = require 'nikita/lib/misc/string'
    {merge} = require 'nikita/lib/misc'
    appender = require '../../lib/appender'
