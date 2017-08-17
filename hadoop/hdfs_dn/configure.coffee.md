
## Configuration

The module extends the various settings set by the "ryba/hadoop/hdfs" module.

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
      service = migration.call @, service, 'ryba/hadoop/hdfs_dn', ['ryba', 'hdfs', 'dn'], require('nikita/lib/misc').merge require('.').use,
        ssl: key: ['ssl']
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hadoop_core: key: ['ryba']
        zookeeper_server: key: ['ryba', 'zookeeper']
        hdfs_dn: key: ['ryba', 'hdfs', 'dn']
      @config.ryba ?= {}
      @config.ryba.hdfs ?= {}
      @config.ryba.hdfs.dn ?= {}
      options = @config.ryba.hdfs.dn ?= service.options

## Environment

Set up Java heap size like in `ryba/hadoop/hdfs_nn`.

      options.pid_dir ?= service.use.hadoop_core.options.hdfs.pid_dir
      options.secure_dn_pid_dir ?= service.use.hadoop_core.options.hdfs.secure_dn_pid_dir
      options.log_dir ?= service.use.hadoop_core.options.hdfs.log_dir
      options.hadoop_opts ?= service.use.hadoop_core.options.hadoop_opts
      options.conf_dir ?= '/etc/hadoop-hdfs-datanode/conf'
      # Java
      options.opts ?= {}
      options.java_opts ?= ''
      options.java_home ?= service.use.java.options.java_home
      options.newsize ?= '200m'
      options.heapsize ?= '1024m'
      options.hadoop_heap ?= service.use.hadoop_core.options.hadoop_heap
      # Misc
      options.sysctl ?= {}
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'

## Identities

      options.hadoop_group ?= merge options.hadoop_group or {}, service.use.hadoop_core.options.hadoop_group
      options.group ?= merge options.group or {}, service.use.hadoop_core.options.hdfs.group
      options.user ?= merge options.user or {}, service.use.hadoop_core.options.hdfs.user

## Configuration

      options.core_site = merge options.core_site or {}, service.use.hadoop_core.options.core_site
      options.site ?= {}
      # Comma separated list of paths. Use the list of directories from $DFS_DATA_DIR.
      # For example, /grid/hadoop/hdfs/dn,/grid1/hadoop/hdfs/dn.
      options.site['dfs.http.policy'] ?= 'HTTPS_ONLY'
      options.site['dfs.datanode.data.dir'] ?= ['file:///var/hdfs/data']
      options.site['dfs.datanode.data.dir'] = options.site['dfs.datanode.data.dir'].join ',' if Array.isArray options.site['dfs.datanode.data.dir']
      # @config.options.site['dfs.datanode.data.dir.perm'] ?= '750'
      options.site['dfs.datanode.data.dir.perm'] ?= '700'
      if options.core_site['hadoop.security.authentication'] is 'kerberos'
        # Default values are retrieved from the official HDFS page called
        # ["SecureMode"][hdfs_secure].
        # Ports must be below 1024, because this provides part of the security
        # mechanism to make it impossible for a user to run a map task which
        # impersonates a DataNode
        # TODO: Move this to 'ryba/hadoop/hdfs_dn'
        options.site['dfs.datanode.address'] ?= '0.0.0.0:1004'
        options.site['dfs.datanode.ipc.address'] ?= '0.0.0.0:50020'
        options.site['dfs.datanode.http.address'] ?= '0.0.0.0:1006'
        options.site['dfs.datanode.https.address'] ?= '0.0.0.0:50475'
      else
        options.site['dfs.datanode.address'] ?= '0.0.0.0:50010'
        options.site['dfs.datanode.ipc.address'] ?= '0.0.0.0:50020'
        options.site['dfs.datanode.http.address'] ?= '0.0.0.0:50075'
        options.site['dfs.datanode.https.address'] ?= '0.0.0.0:50475'

## Centralized Cache Management

Centralized cache management in HDFS is an explicit caching mechanism that enables you to specify paths to directories or files that will be cached by HDFS.

If you get the error "Cannot start datanode because the configured max locked 
memory size... is more than the datanode's available RLIMIT_MEMLOCK ulimit," 
that means that the operating system is imposing a lower limit on the amount of 
memory that you can lock than what you have configured.

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      options.krb5.principal ?= "dn/#{service.node.fqdn}@#{options.krb5.realm}"
      options.krb5.keytab ?= '/etc/security/keytabs/dn.service.keytab'
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= @config.krb5_client.admin[options.krb5.realm]
      # Configuration in "core-site.xml"
      options.site['dfs.datanode.kerberos.principal'] ?= options.krb5.principal.replace service.node.fqdn, '_HOST'
      options.site['dfs.datanode.keytab.file'] ?= options.krb5.keytab

## SSL

      options.ssl = merge options.ssl or {}, service.use.hadoop_core.options.ssl
      options.ssl_server = merge options.ssl_server or {}, service.use.hadoop_core.options.ssl_server
      options.ssl_client = merge options.ssl_client or {}, service.use.hadoop_core.options.ssl_client

## Tuning

      dataDirs = options.site['dfs.datanode.data.dir'].split(',')
      if dataDirs.length > 3
        options.site['dfs.datanode.failed.volumes.tolerated'] ?= '1'
      else
        options.site['dfs.datanode.failed.volumes.tolerated'] ?= '0'
      # Validation
      if options.site['dfs.datanode.failed.volumes.tolerated'] >= dataDirs.length
        throw Error 'Number of failed volumes must be less than total volumes'
      options.datanode_opts ?= ''

## Storage-Balancing Policy

      # http://gbif.blogspot.fr/2015/05/dont-fill-your-hdfs-disks-upgrading-to.html
      # http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/admin_dn_storage_balancing.html
      options.site['dfs.datanode.fsdataset.volume.choosing.policy'] ?= 'org.apache.hadoop.hdfs.server.datanode.fsdataset.AvailableSpaceVolumeChoosingPolicy'
      options.site['dfs.datanode.available-space-volume-choosing-policy.balanced-space-threshold'] ?= '10737418240' # 10GB
      options.site['dfs.datanode.available-space-volume-choosing-policy.balanced-space-preference-fraction'] ?= '1.0'
      # Note, maybe do a better estimation of du.reserved inside capacity
      # currently, 50GB throw DataXceiver exception inside vagrant vm
      options.site['dfs.datanode.du.reserved'] ?= '1073741824' # 1GB, also default in ambari

## HDFS Balancer Performance increase (Fast Mode)

      # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_hdfs-administration/content/configuring_balancer.html
      # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_hdfs-administration/content/recommended_configurations.html
      options.site['dfs.datanode.balance.max.concurrent.moves'] ?=  Math.max 5, dataDirs.length * 4
      options.site['dfs.datanode.balance.bandwidthPerSec'] ?= 10737418240 #(10 GB/s) default is 1048576 (=1MB/s)

## HDFS Short-Circuit Local Reads

[Short Circuit] need to be configured on the DataNode and the client.

[Short Circuit]: https://hadoop.apache.org/docs/r2.4.1/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html

      options.site['dfs.client.read.shortcircuit'] ?= if @has_service 'ryba/hadoop/hdfs_dn' then 'true' else 'false'
      options.site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'

## Metrics

      options.hadoop_metrics ?= service.use.hadoop_core.options.hadoop_metrics

## Configuration for Log4J

      options.log4j ?= {}
      options.root_logger ?= 'INFO,RFA'
      options.security_logger ?= 'INFO,RFAS'
      options.audit_logger ?= 'INFO,RFAAUDIT'
      if @config.log4j?.services?
        if @config.log4j?.remote_host? && @config.log4j?.remote_port? && ('ryba/hadoop/hdfs_dn' in @config.log4j.services)
          # Root logger
          if options.root_logger.indexOf(options.socket_client) is -1
          then options.root_logger += ",#{options.socket_client}"
          # Security Logger
          if options.security_logger.indexOf(options.socket_client) is -1
          then options.security_logger += ",#{options.socket_client}"
          # Audit Logger
          if options.audit_logger.indexOf(options.socket_client) is -1
          then options.audit_logger += ",#{options.socket_client}"
          # adding SOCKET appender
          options.socket_client ?= "SOCKET"
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

## Wait

      options.wait_krb5_client = service.use.krb5_client.options.wait
      options.wait_zookeeper_server = service.use.zookeeper_server[0].options.wait
      options.wait = {}
      options.wait.ipc = for srv in service.use.hdfs_dn
        srv.options.site ?= {}
        is_krb5 = options.core_site['hadoop.security.authentication'] is 'kerberos'
        property = if is_krb5 then else 
        addr = if srv.options.site['dfs.datanode.address']?
        then srv.options.site['dfs.datanode.address']
        else unless is_krb5 then '0.0.0.0:50010' else  '0.0.0.0:1004'
        [_, port] = addr.split ':'
        host: srv.node.fqdn, port: port
      options.wait.http = for srv in service.use.hdfs_dn
        srv.options.site ?= {}
        policy = srv.options.site['dfs.http.policy']
        if srv.options.site['dfs.http.policy']?
        then srv.options.site['dfs.http.policy']
        else options.site['dfs.http.policy']
        protocol = if policy is 'HTTP_ONLY' then 'http' else 'https'
        addr = if srv.options.site["dfs.datanode.#{protocol}.address"]?
        then srv.options.site["dfs.datanode.#{protocol}.address"]
        else options.site["dfs.datanode.#{protocol}.address"]
        [_, port] = addr.split ':'
        host: srv.node.fqdn, port: port

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
