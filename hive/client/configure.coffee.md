
# Hive Client Configuration

Example:

```json
{
  "ryba": {
    "hive": {
      "client": {
        opts": "-Xmx4096m",
        heapsize": "1024"
      }
    }
  }
}
```

    module.exports = ->
      service = migration.call @, service, 'ryba/hive/client', ['ryba', 'hive', 'client'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        test_user: key: ['ryba', 'test_user']
        # mapred_client: key: ['ryba', 'mapred']
        # zookeeper_server: key: ['ryba', 'zookeeper']
        hadoop_core: key: ['ryba']
        hdfs_client: key: ['ryba', 'hdfs_client']
        yarn_client: key: ['ryba', 'yarn_client']
        mapred_client: key: ['ryba', 'mapred']
        tez: key: ['ryba', 'tez']
        # hive_metastore: key: ['ryba', 'hive', 'metastore']
        hive_hcatalog: key: ['ryba', 'hive', 'hcatalog']
        # hive_server2: key: ['ryba', 'hive', 'server2']
        # hive_client: key: ['ryba', 'hive']
        # hbase_thrift: key: ['ryba', 'hbase', 'thrift']
        # hbase_client: key: ['ryba', 'hbase', 'client']
        # phoenix_client: key: ['ryba', 'phoenix'] # actuall, phoenix expose no configuration
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ranger_hdfs: key: ['ryba', 'ranger', 'hdfs']
      @config.ryba ?= {}
      @config.ryba.hive ?= {}
      options = @config.ryba.hive.client = service.options

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive/conf'
      # Opts and Java
      options.java_home ?= service.use.java.options.java_home
      options.env ?= {}
      options.opts = ""
      options.heapsize = 1024
      options.aux_jars ?= service.use.hive_hcatalog[0].options.aux_jars
      # Misc
      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.force_check ?= false

## Identities

      options.user = merge {}, service.use.hive_hcatalog[0].options.user, options.user
      options.group = merge {}, service.use.hive_hcatalog[0].options.group, options.group
      options.ranger_admin ?= service.use.ranger_admin.options.admin if service.use.ranger_admin

## Configuration

      options.hive_site ?= {}
      # Tuning
      # [Christian Prokopp comments](http://www.quora.com/What-are-the-best-practices-for-using-Hive-What-settings-should-we-enable-most-of-the-time)
      # [David Streever](https://streever.atlassian.net/wiki/display/HADOOP/Hive+Performance+Tips)
      # options.hive_site['hive.exec.compress.output'] ?= 'true'
      options.hive_site['hive.exec.compress.intermediate'] ?= 'true'
      options.hive_site['hive.auto.convert.join'] ?= 'true'
      options.hive_site['hive.cli.print.header'] ?= 'false'
      # options.hive_site['hive.mapjoin.smalltable.filesize'] ?= '50000000'

      options.hive_site['hive.execution.engine'] ?= 'tez'
      options.hive_site['hive.tez.container.size'] ?= service.use.tez.options.tez_site['tez.am.resource.memory.mb']
      options.hive_site['hive.tez.java.opts'] ?= service.use.tez.options.tez_site['hive.tez.java.opts']
      # Size per reducer. The default in Hive 0.14.0 and earlier is 1 GB. In
      # Hive 0.14.0 and later the default is 256 MB.
      # HDP set it to 64 MB which seems wrong
      # Don't know if this default value should be hardcoded or estimated based
      # on cluster capacity
      options.hive_site['hive.exec.reducers.bytes.per.reducer'] ?= '268435456'

## Client Metastore Configuration

      for property in [
        'hive.metastore.uris'
        'hive.security.authorization.enabled'
        'hive.security.metastore.authorization.manager'
        # 'hive.security.metastore.authenticator.manager'
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
        # 'hive.metastore.kerberos.principal'
        # 'hive.metastore.pre.event.listeners'
        'hive.optimize.mapjoin.mapreduce'
        'hive.heapsize'
        'hive.auto.convert.sortmerge.join.noconditionaltask'
        'hive.exec.max.created.files'
        # Transaction, read/write locks
      ] then options.hive_site[property] ?= service.use.hive_hcatalog[0].options.hive_site[property]

## Configure SSL

      options.truststore_location ?= "#{options.conf_dir}/truststore"
      options.truststore_password ?= "ryba123"

## Test

      options.ranger_hdfs_install = service.use.ranger_hdfs[0].options.install if service.use.ranger_hdfs
      options.test = merge {}, service.use.test_user.options, options.test
      # Hive Hcatalog
      options.hive_hcatalog = for srv in service.use.hive_hcatalog
        # fqdn: srv.options.fqdn
        hostname: srv.options.hostname
        # hive_site: srv.options.hive_site

## Wait

      options.wait_hive_hcatalog = service.use.hive_hcatalog[0].options.wait
      options.wait_ranger_admin = service.use.ranger_admin.options.wait if service.use.ranger_admin

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'

## Notes

Example of a minimal client configuration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <property>
    <name>hive.metastore.kerberos.keytab.file</name>
    <value>/etc/security/keytabs/hive.service.keytab</value>
  </property>
  <property>
    <name>hive.metastore.kerberos.principal</name>
    <value>hive/_HOST@ADALTAS.COM</value>
  </property>
  <property>
    <name>hive.metastore.sasl.enabled</name>
    <value>true</value>
  </property>
  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://big3.big:9083</value>
  </property>
</configuration>
```
