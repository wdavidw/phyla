
## Configuration

The module extends the various settings set by the "@rybajs/metal/hadoop/hdfs" module.

Unless specified otherwise, the number of tolerated failed volumes is set to "1"
if at least 4 disks are used for storage.

*   `java_opts` (string)
    Datanode Java options.

Example:

```json
{
  "ryba": {
    "hdfs": {
      "datanode_opts": "-Xmx1024m",
      "sysctl": {
        "vm.swappiness": 0,
        "vm.overcommit_memory": 1,
        "vm.overcommit_ratio": 100,
        "net.core.somaxconn": 1024
    }
  }
}
```

    module.exports = (service) ->
      options = service.options

## Environment

Set up Java heap size like in `@rybajs/metal/hadoop/hdfs_nn`.

      options.pid_dir ?= service.deps.hadoop_core.options.hdfs.pid_dir
      options.secure_dn_pid_dir ?= service.deps.hadoop_core.options.hdfs.secure_dn_pid_dir
      options.log_dir ?= service.deps.hadoop_core.options.hdfs.log_dir
      options.conf_dir ?= '/etc/hadoop-hdfs-datanode/conf'
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.newsize ?= '200m'
      options.heapsize ?= '1024m'
      options.hadoop_heap ?= service.deps.hadoop_core.options.hadoop_heap
      # Misc
      options.clean_logs ?= false
      options.hadoop_opts ?= service.deps.hadoop_core.options.hadoop_opts
      options.sysctl ?= {}
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.fqdn = service.node.fqdn

## Identities

      options.hadoop_group = merge service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge service.deps.hadoop_core.options.hdfs.group, options.group 
      options.user = merge service.deps.hadoop_core.options.hdfs.user, options.user

## Kerberos

      # Kerberos HDFS Admin
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

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

      options.core_site = merge service.deps.hadoop_core.options.core_site, options.core_site or {}
      # Note: moved during masson migration from nn to dn
      options.core_site['io.compression.codecs'] ?= "org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec,com.hadoop.compression.lzo.LzoCodec"
      options.hdfs_site ?= {}
      # Comma separated list of paths. Use the list of directories from $DFS_DATA_DIR.
      # For example, /grid/hadoop/hdfs/dn,/grid1/hadoop/hdfs/dn.
      options.hdfs_site['dfs.http.policy'] ?= 'HTTPS_ONLY'
      options.hdfs_site['dfs.datanode.data.dir'] ?= ['file:///var/hdfs/data']
      options.hdfs_site['dfs.datanode.data.dir'] = options.hdfs_site['dfs.datanode.data.dir'].join ',' if Array.isArray options.hdfs_site['dfs.datanode.data.dir']
      # options.hdfs_site['dfs.datanode.data.dir.perm'] ?= '750'
      options.hdfs_site['dfs.datanode.data.dir.perm'] ?= '700'
      if options.core_site['hadoop.security.authentication'] is 'kerberos'
        # Default values are retrieved from the official HDFS page called
        # ["SecureMode"][hdfs_secure].
        # Ports must be below 1024, because this provides part of the security
        # mechanism to make it impossible for a user to run a map task which
        # impersonates a DataNode
        # TODO: Move this to '@rybajs/metal/hadoop/hdfs_dn'
        options.hdfs_site['dfs.datanode.address'] ?= '0.0.0.0:1004'
        options.hdfs_site['dfs.datanode.ipc.address'] ?= '0.0.0.0:50020'
        options.hdfs_site['dfs.datanode.http.address'] ?= '0.0.0.0:1006'
        options.hdfs_site['dfs.datanode.https.address'] ?= '0.0.0.0:9865'
      else
        options.hdfs_site['dfs.datanode.address'] ?= '0.0.0.0:50010'
        options.hdfs_site['dfs.datanode.ipc.address'] ?= '0.0.0.0:50020'
        options.hdfs_site['dfs.datanode.http.address'] ?= '0.0.0.0:9864'
        options.hdfs_site['dfs.datanode.https.address'] ?= '0.0.0.0:9865'

## Centralized Cache Management

Centralized cache management in HDFS is an explicit caching mechanism that enables you to specify paths to directories or files that will be cached by HDFS.

If you get the error "Cannot start datanode because the configured max locked 
memory size... is more than the datanode's available RLIMIT_MEMLOCK ulimit," 
that means that the operating system is imposing a lower limit on the amount of 
memory that you can lock than what you have configured.

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      options.krb5.principal ?= "dn/#{service.node.fqdn}@#{options.krb5.realm}"
      options.krb5.keytab ?= '/etc/security/keytabs/dn.service.keytab'
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Configuration in "core-site.xml"
      options.hdfs_site['dfs.datanode.kerberos.principal'] ?= options.krb5.principal.replace service.node.fqdn, '_HOST'
      options.hdfs_site['dfs.datanode.keytab.file'] ?= options.krb5.keytab

## SSL

      options.ssl = merge service.deps.hadoop_core.options.ssl, options.ssl
      options.ssl_server = merge service.deps.hadoop_core.options.ssl_server, options.ssl_server or {}
      options.ssl_client = merge service.deps.hadoop_core.options.ssl_client, options.ssl_client or {}

## Tuning

      dataDirs = options.hdfs_site['dfs.datanode.data.dir'].split(',')
      if dataDirs.length > 3
        options.hdfs_site['dfs.datanode.failed.volumes.tolerated'] ?= '1'
      else
        options.hdfs_site['dfs.datanode.failed.volumes.tolerated'] ?= '0'
      # Validation
      if options.hdfs_site['dfs.datanode.failed.volumes.tolerated'] >= dataDirs.length
        throw Error 'Number of failed volumes must be less than total volumes'
      options.datanode_opts ?= ''

## Storage-Balancing Policy

      # http://gbif.blogspot.fr/2015/05/dont-fill-your-hdfs-disks-upgrading-to.html
      # http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_dn_storage_balancing.html
      options.hdfs_site['dfs.datanode.fsdataset.volume.choosing.policy'] ?= 'org.apache.hadoop.hdfs.server.datanode.fsdataset.AvailableSpaceVolumeChoosingPolicy'
      options.hdfs_site['dfs.datanode.available-space-volume-choosing-policy.balanced-space-threshold'] ?= '10737418240' # 10GB
      options.hdfs_site['dfs.datanode.available-space-volume-choosing-policy.balanced-space-preference-fraction'] ?= '1.0'
      # Note, maybe do a better estimation of du.reserved inside capacity
      # currently, 50GB throw DataXceiver exception inside vagrant vm
      options.hdfs_site['dfs.datanode.du.reserved'] ?= '1073741824' # 1GB, also default in ambari

## HDFS Balancer Performance increase (Fast Mode)

      # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_hdfs-administration/content/configuring_balancer.html
      # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_hdfs-administration/content/recommended_configurations.html
      options.hdfs_site['dfs.datanode.balance.max.concurrent.moves'] ?=  Math.max 5, dataDirs.length * 4
      options.hdfs_site['dfs.datanode.balance.bandwidthPerSec'] ?= 10737418240 #(10 GB/s) default is 1048576 (=1MB/s)

## HDFS Short-Circuit Local Reads

[Short Circuit] need to be configured on the DataNode and the client.

[Short Circuit]: https://hadoop.apache.org/docs/r2.4.1/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html

      options.hdfs_site['dfs.client.read.shortcircuit'] ?= if (service.node.services.some (srv) -> srv.module is '@rybajs/metal/hadoop/hdfs_dn') then 'true' else 'false'
      options.hdfs_site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'

## Metrics

      options.metrics = merge service.deps.metrics?.options, options.metrics
      options.metrics.config ?= {}
      options.metrics.sinks ?= {}
      options.metrics.sinks.file_enabled ?= true
      options.metrics.sinks.ganglia_enabled ?= false
      options.metrics.sinks.graphite_enabled ?= false
      # File sink
      if options.metrics.sinks.file_enabled
        options.metrics.config["datanode.sink.file.class"] ?= 'org.apache.hadoop.metrics2.sink.FileSink'
        options.metrics.config['datanode.sink.file.filename'] ?= 'datanode-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if options.metrics.sinks.ganglia_enabled
        options.metrics.config["datanode.sink.ganglia.class"] ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
        options.metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of options.sinks.ganglia.config if service.deps.metrics?.options?.sinks?.ganglia_enabled
      # Graphite Sink
      if options.metrics.sinks.graphite_enabled
        throw Error 'Missing remote_host ryba.hdfs.dn.metrics.sinks.graphite.config.server_host' unless options.metrics.sinks.graphite.config.server_host?
        throw Error 'Missing remote_port ryba.hdfs.dn.metrics.sinks.graphite.config.server_port' unless options.metrics.sinks.graphite.config.server_port?
        options.metrics.config["datanode.sink.graphite.class"] ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
        options.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.graphite.config if service.deps.metrics?.options?.sinks?.graphite_enabled

## Configuration for Log4J
Inherits log4j configuration from the `@rybajs/metal/log4j`. The rendered file uses the variable
`options.log4j.properties`

      options.log4j = merge service.deps.log4j?.options, options.log4j
      options.log4j.properties ?= {}
      options.log4j.root_logger ?= 'INFO,RFA'
      options.log4j.security_logger ?= 'INFO,RFAS'
      options.log4j.audit_logger ?= 'INFO,RFAAUDIT'
      if options.log4j.remote_host? and options.log4j.remote_port?
        # adding SOCKET appender
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
        options.opts['hadoop.log.application'] ?= 'datanode'
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

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.deps.hdfs_dn
        is_krb5 = options.core_site['hadoop.security.authentication'] is 'kerberos'
        addr = if srv.options.hdfs_site?['dfs.datanode.address']?
        then srv.options.hdfs_site['dfs.datanode.address']
        else unless is_krb5 then '0.0.0.0:50010' else  '0.0.0.0:1004'
        [_, port] = addr.split ':'
        host: srv.node.fqdn, port: port
      options.wait.ipc = for srv in service.deps.hdfs_dn
        addr = if srv.options.hdfs_site?['dfs.datanode.ipc.address']?
        then srv.options.hdfs_site['dfs.datanode.ipc.address']
        else '0.0.0.0:50020'
        [_, port] = addr.split ':'
        host: srv.node.fqdn, port: port
      options.wait.http = for srv in service.deps.hdfs_dn
        policy = if srv.options.hdfs_site?['dfs.http.policy']?
        then srv.options.hdfs_site['dfs.http.policy']
        else options.hdfs_site['dfs.http.policy']
        protocol = if policy is 'HTTP_ONLY' then 'http' else 'https'
        addr = if srv.options.hdfs_site?["dfs.datanode.#{protocol}.address"]?
        then srv.options.hdfs_site["dfs.datanode.#{protocol}.address"]
        else options.hdfs_site["dfs.datanode.#{protocol}.address"]
        [_, port] = addr.split ':'
        host: srv.node.fqdn, port: port
      # current datanode wait (local one)  
      is_krb5 = options.core_site['hadoop.security.authentication'] is 'kerberos'
      policy = options.hdfs_site['dfs.http.policy']
      http_addr = options.hdfs_site["dfs.datanode.#{protocol}.address"]
      tcp_addr = unless is_krb5 then '0.0.0.0:50010' else  '0.0.0.0:1004'
      ipc_addr = '0.0.0.0:50020'
      protocol = if policy is 'HTTP_ONLY' then 'http' else 'https'
      options.wait.tcp_local =
        host: tcp_addr.split(':')[0], port: tcp_addr.split(':')[1]
      options.wait.ipc_local =
        host: ipc_addr.split(':')[0], port: ipc_addr.split(':')[1]
      options.wait.http_local =
        host: http_addr.split(':')[0], port: http_addr.split(':')[1]


## Dependencies

    {merge} = require 'mixme'
    appender = require '../../lib/appender'
