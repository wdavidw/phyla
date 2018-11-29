
# Hadoop YARN Timeline Server Configure

```json
{ "ryba": { "yarn": { "ats": {
  "opts": "",
  "heapsize": "1024"
} } } }
```

    module.exports = (service) ->
      options = service.options
      throw Error 'CAn not have more than one instance of ryba/hadoop/yarn_tr_hbase_embedded' if service.deps.yarn_tr_hbase_embedded?.length > 1

## Identities

      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.deps.hadoop_core.options.yarn.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.yarn.user, options.user
      options.ats_user = service.deps.hadoop_core.options.ats.user
      options.ats_group = service.deps.hadoop_core.options.ats.group
      options.hdfs_user = service.deps.hadoop_core.options.hdfs.user
      options.hdfs_group = service.deps.hadoop_core.options.hdfs.group

## Ranger

      options.ranger_admin ?= service.deps.ranger_admin[0].options.admin if service.deps.ranger_admin?.length

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      options.yarn_ats_user ?= {}
      options.yarn_ats_user.principal  ?= "#{options.ats_user.name}@#{options.krb5.realm}"
      options.yarn_ats_user.keytab  ?= "/etc/security/keytabs/yarn-ats.hbase-client.headless.keytab"
      options.yarn_ats_user.password ?= 'ats123'
  
## Environment

      # Layout
      options.home ?= '/usr/hdp/current/hadoop-yarn-timelinereader'
      options.log_dir ?= '/var/log/hadoop/yarn'
      options.pid_dir ?= '/var/run/hadoop/yarn'
      options.conf_dir ?= '/etc/embedded-yarn-ats-hbase/conf'
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.heapsize ?= '1024m'
      options.newsize ?= '200m'
      # Misc
      options.fqdn = service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user
      options.nn_url = service.deps.hdfs_client[0].options.nn_url

## System Options

      options.opts ?= {}
      options.opts.master_base ?= ''
      options.opts.master_java_properties ?= {}
      options.opts.master_jvm ?= {}
      options.opts.master_jvm['-Xms'] ?= options.master_heapsize
      options.opts.master_jvm['-Xmx'] ?= options.master_heapsize
      options.opts.master_jvm['-XX:NewSize='] ?= options.master_newsize #should be 1/8 of heapsize
      options.opts.master_jvm['-XX:MaxNewSize='] ?= options.master_newsize #should be 1/8 of heapsize
      options.opts.regionserver_base ?= ''
      options.opts.regionserver_java_properties ?= {}
      options.opts.regionserver_jvm ?= {}
      options.opts.regionserver_jvm['-Xms'] ?= options.rs_heapsize
      options.opts.regionserver_jvm['-Xmx'] ?= options.rs_heapsize
      options.opts.regionserver_jvm['-XX:NewSize='] ?= options.rs_newsize #should be 1/8 of heapsize
      options.opts.regionserver_jvm['-XX:MaxNewSize='] ?= options.rs_newsize #should be 1/8 of heapsize

## Configuration

      # Hadoop core "core-site.xml"
      options.core_site = merge {}, service.deps.hdfs_client[0].options.core_site, options.core_site or {}
      # HDFS client "hdfs-site.xml"
      options.hdfs_site = merge {}, service.deps.hdfs_client[0].options.hdfs_site, options.hdfs_site or {}
      # The hostname of the Timeline service web application.
      options.hbase_site ?= {}

## Embedded HBase Configuration

### Kerberos

      options.hbase_site['hbase.security.authentication'] ?= service.deps.hadoop_core.options.security
      options.hbase_site['hbase.master.kerberos.principal'] ?= "yarn-ats-hbase/_HOST@#{options.krb5.realm}"
      options.hbase_site['hbase.master.keytab.file'] ?= '/etc/security/keytabs/yarn-ats.hbase-master.service.keytab'
      options.hbase_site['hbase.regionserver.kerberos.principal'] ?= "yarn-ats-hbase/_HOST@#{options.krb5.realm}"
      options.hbase_site['hbase.regionserver.keytab.file'] ?= '/etc/security/keytabs/yarn-ats.hbase-regionserver.service.keytab'
      options.opts.master_java_properties['java.security.auth.login.config'] ?= "#{options.conf_dir}/yarn_hbase_master_jaas.conf"
      options.opts.regionserver_java_properties['java.security.auth.login.config'] ?= "#{options.conf_dir}/yarn_hbase_regionserver_jaas.conf"

### Port

      options.hbase_site['hbase.master.port'] ?= '17000'
      options.hbase_site['hbase.master.info.port'] ?= '17010'
      options.hbase_site['hbase.regionserver.info.port'] ?= '17030'
      options.hbase_site['hbase.regionserver.port'] ?= '17020'

### ZK and HDFS

      options.hbase_site['hbase.rootdir'] ?= "#{service.deps.hdfs_nn[0].options.core_site['fs.defaultFS']}/atsv2/hbase/data"
      options.hbase_site['hbase.zookeeper.quorum'] ?= service.deps.zookeeper_server.map( (srv) -> srv.node.fqdn ).join ','
      options.hbase_site['hbase.zookeeper.property.clientPort'] ?= service.deps.zookeeper_server[0].options.config['clientPort']
      options.hbase_site['hbase.zookeeper.useMulti'] ?= 'true'
      options.hbase_site['zookeeper.recovery.retry'] ?= '6'
      options.hbase_site['zookeeper.session.timeout'] ?= '90000'
      options.hbase_site['zookeeper.znode.parent'] ?= '/atsv2-hbase-secure'

### Advanced

      options.hbase_site['hbase.rpc.protection'] ?= 'authentication'
      options.hbase_site['dfs.domain.socket.path'] ?= '/var/lib/hadoop-hdfs/dn_socket'
      options.hbase_site['hbase.bucketcache.ioengine'] ?= ''
      options.hbase_site['hbase.bucketcache.percentage.in.combinedcache'] ?= ''
      options.hbase_site['hbase.bucketcache.size'] ?= ''
      options.hbase_site['hbase.client.keyvalue.maxsize'] ?= '1048576'
      options.hbase_site['hbase.client.retries.number'] ?= '7'
      options.hbase_site['hbase.client.scanner.caching'] ?= '100'
      options.hbase_site['hbase.cluster.distributed'] ?= 'true'
      options.hbase_site['hbase.coprocessor.master.classes'] ?= 'org.apache.hadoop.hbase.security.access.AccessController'
      options.hbase_site['hbase.coprocessor.region.classes'] ?= 'org.apache.hadoop.hbase.security.token.TokenProvider,org.apache.hadoop.hbase.security.access.AccessController'
      options.hbase_site['hbase.coprocessor.regionserver.classes'] ?= ''
      options.hbase_site['hbase.defaults.for.version.skip'] ?= 'true'
      options.hbase_site['hbase.hregion.majorcompaction'] ?= '604800000'
      options.hbase_site['hbase.hregion.majorcompaction.jitter'] ?= '0.50'
      options.hbase_site['hbase.hregion.max.filesize'] ?= '10737418240'
      options.hbase_site['hbase.hregion.memstore.block.multiplier'] ?= '4'
      options.hbase_site['hbase.hregion.memstore.flush.size'] ?= '134217728'
      options.hbase_site['hbase.hregion.memstore.mslab.enabled'] ?= 'true'
      options.hbase_site['hbase.hstore.blockingStoreFiles'] ?= '10'
      options.hbase_site['hbase.hstore.compaction.max'] ?= '10'
      options.hbase_site['hbase.hstore.compactionThreshold'] ?= '3'
      options.hbase_site['hbase.local.dir'] ?= '${hbase.tmp.dir}/local'
      options.hbase_site['hbase.master.info.bindAddress'] ?= '0.0.0.0'
      options.hbase_site['hbase.master.namespace.init.timeout'] ?= '2400000'
      options.hbase_site['hbase.master.ui.readonly'] ?= 'false'
      options.hbase_site['hbase.master.wait.on.regionservers.timeout'] ?= '30000'
      options.hbase_site['hbase.regionserver.executor.openregion.threads'] ?= '20'
      options.hbase_site['hbase.regionserver.global.memstore.size'] ?= '0.4'
      options.hbase_site['hbase.regionserver.handler.count'] ?= '30'
      options.hbase_site['hbase.rpc.timeout'] ?= '90000'
      options.hbase_site['hbase.security.authorization'] ?= 'true'
      options.hbase_site['hbase.superuser'] ?= 'yarn'
      options.hbase_site['hbase.tmp.dir'] ?= '/tmp/hbase-yarn-ats'
      # Comma separated list of Zookeeper servers (match to
      # what is specified in zoo.cfg but without portnumbers)
      options.hbase_site['hfile.block.cache.size'] ?= '0.4'

## SSL

      options.hbase_site['hbase.ssl.enabled'] ?= 'true'
      # will read ssl-server and ssl-client from /etc/hadoop/conf
  
## Metrics

      options.metrics = merge {}, service.deps.hadoop_core.options.metrics, options.metrics

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_hdfs_nn = service.deps.hdfs_nn[0].options.wait
      options.wait = {}
      options.wait.master_rpc ?=
        host: options.fqdn
        port: options.hbase_site['hbase.master.port']
      options.wait.master_http ?=
        host: options.fqdn
        port: options.hbase_site['hbase.master.info.port']
      options.wait.regionserver_rpc ?=
        host: options.fqdn
        port: options.hbase_site['hbase.regionserver.port']
      options.wait.regionserver_http ?=
        host: options.fqdn
        port: options.hbase_site['hbase.regionserver.info.port']
      options.wait_ranger_admin = service.deps.ranger_admin[0].options.wait if service.deps.ranger_admin?.length?

## Dependencies

    {merge} = require 'nikita/lib/misc'
    path = require 'path'