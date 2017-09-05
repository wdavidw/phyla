
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
      hcat_ctxs = @contexts 'ryba/hive/hcatalog'
      throw Error "No HCatalog server declared" unless hcat_ctxs[0]
      {mapred, tez} = @config.ryba
      {java_home} = @config.java
      hive = @config.ryba.hive ?= {}
      options = hive.client ?= {}

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive/conf'
      # Opts and Java
      options.env ?= {}
      options.opts = ""
      options.heapsize = 1024
      options.aux_jars ?= hcat_ctxs[0].config.ryba.hive.hcatalog.aux_jars

## Identities

      options.user = merge hcat_ctxs[0].config.ryba.hive.user, options.user
      options.group = merge hcat_ctxs[0].config.ryba.hive.group, options.group

## Configuration

      options.site ?= {}
      # Tuning
      # [Christian Prokopp comments](http://www.quora.com/What-are-the-best-practices-for-using-Hive-What-settings-should-we-enable-most-of-the-time)
      # [David Streever](https://streever.atlassian.net/wiki/display/HADOOP/Hive+Performance+Tips)
      # options.site['hive.exec.compress.output'] ?= 'true'
      options.site['hive.exec.compress.intermediate'] ?= 'true'
      options.site['hive.auto.convert.join'] ?= 'true'
      options.site['hive.cli.print.header'] ?= 'false'
      # options.site['hive.mapjoin.smalltable.filesize'] ?= '50000000'

      options.site['hive.execution.engine'] ?= 'tez'
      options.site['hive.tez.container.size'] ?= tez.site['tez.am.resource.memory.mb']
      options.site['hive.tez.java.opts'] ?= tez.site['hive.tez.java.opts']
      # Size per reducer. The default in Hive 0.14.0 and earlier is 1 GB. In
      # Hive 0.14.0 and later the default is 256 MB.
      # HDP set it to 64 MB which seems wrong
      # Don't know if this default value should be hardcoded or estimated based
      # on cluster capacity
      options.site['hive.exec.reducers.bytes.per.reducer'] ?= '268435456'

      # Import HCatalog properties

      # properties = [
      #   'hive.metastore.uris'
      #   'hive.security.authorization.enabled'
      #   'hive.server2.authentication'
      #   # 'hive.security.authorization.manager'
      #   # 'hive.security.metastore.authorization.manager'
      #   # 'hive.security.authenticator.manager'
      #   # Transaction, read/write locks
      #   'hive.support.concurrency'
      #   'hive.zookeeper.quorum'
      #   'hive.enforce.bucketing'
      #   'hive.exec.dynamic.partition.mode'
      #   'hive.txn.manager'
      #   'hive.txn.timeout'
      #   'hive.txn.max.open.batch'
      #   'hive.cluster.delegation.token.store.zookeeper.connectString'
      #   'hive.cluster.delegation.token.store.class'
      # ]
      # 
      # for property in properties then options.site[property] ?= hcat_ctxs[0].config.ryba.hive.site[property]

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
      ] then options.site[property] ?= hcat_ctxs[0].config.ryba.hive.hcatalog.site[property]

## Configure SSL

      options.truststore_location ?= "#{options.conf_dir}/truststore"
      options.truststore_password ?= "ryba123"

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
