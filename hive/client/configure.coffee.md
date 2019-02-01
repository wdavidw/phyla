
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

    module.exports = (service) ->
      options = service.options

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive/conf'
      # Opts and Java
      options.java_home ?= service.deps.java.options.java_home
      options.env ?= {}
      options.opts = ""
      options.heapsize = 1024
      options.aux_jars_paths ?= {}
      for path, val of service.deps.hive_hcatalog[0].options.aux_jars_paths
        options.aux_jars_paths[path] ?= val
      #aux_jars forced by ryba to guaranty consistency
      options.aux_jars = "#{Object.keys(options.aux_jars_paths).join ':'}"
      # Misc
      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.force_check ?= false
      options.phoenix_enabled ?= !!service.deps.phoenix_client

## Identities

      options.user = merge {}, service.deps.hive_hcatalog[0].options.user, options.user
      options.group = merge {}, service.deps.hive_hcatalog[0].options.group, options.group
      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin

## Kerberos

      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

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
      options.hive_site['hive.tez.container.size'] ?= service.deps.tez.options.tez_site['tez.am.resource.memory.mb']
      options.hive_site['hive.tez.java.opts'] ?= service.deps.tez.options.tez_site['hive.tez.java.opts']
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
      ] then options.hive_site[property] ?= service.deps.hive_hcatalog[0].options.hive_site[property]

## Configure SSL

      options.truststore_location ?= "#{options.conf_dir}/truststore"
      options.truststore_password ?= "ryba123"

## Test

      options.ranger_hdfs_install = service.deps.ranger_hdfs[0].options.install if service.deps.ranger_hdfs
      options.test = merge {}, service.deps.test_user.options, options.test
      # Hive Hcatalog
      options.hive_hcatalog = for srv in service.deps.hive_hcatalog
        # fqdn: srv.options.fqdn
        hostname: srv.options.hostname
        # hive_site: srv.options.hive_site

## Wait

      options.wait_hive_hcatalog = service.deps.hive_hcatalog[0].options.wait
      options.wait_ranger_admin = service.deps.ranger_admin.options.wait if service.deps.ranger_admin

## Dependencies

    {merge} = require '@nikita/core/lib/misc'

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
