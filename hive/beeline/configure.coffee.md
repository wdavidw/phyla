
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
      service = migration.call @, service, 'ryba/hive/beeline', ['ryba', 'hive', 'beeline'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        test_user: key: ['ryba', 'test_user']
        hadoop_core: key: ['ryba']
        hive_hcatalog: key: ['ryba', 'hive', 'hcatalog']
        hive_server2: key: ['ryba', 'hive', 'server2']
        spark_thrift_server: key: ['ryba', 'spark']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ranger_hive: key: ['ryba', 'ranger', 'hive']
      @config.ryba ?= {}
      @config.ryba.hbase ?= {}
      options = @config.ryba.hive.beeline = service.options

## Identities

      options.hadoop_group = merge {}, service.use.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge service.use.hive_server2[0].options.group, options.group
      options.user = merge service.use.hive_server2[0].options.user, options.user
      options.ranger_admin ?= service.use.ranger_admin.options.admin if service.use.ranger_admin

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive/conf'
      # Opts and Java
      options.java_home ?= service.use.java.options.java_home
      options.opts = ""
      options.heapsize = 1024
      options.aux_jars ?= service.use.hive_hcatalog[0].options.aux_jars
      # Misc
      options.hostname ?= service.node.hostname
      options.force_check ?= false

## Import HiveServer2 Configuration

      options.hive_site ?= {}
      for property in [
        'hive.server2.authentication'
        # Transaction, read/write locks
        'hive.execution.engine'
        'hive.zookeeper.quorum'
        'hive.server2.thrift.sasl.qop'
        'hive.optimize.mapjoin.mapreduce'
        'hive.heapsize'
        'hive.auto.convert.sortmerge.join.noconditionaltask'
        'hive.exec.max.created.files'
      ] then options.hive_site[property] ?= service.use.hive_server2[0].options.hive_site[property]

## Configure SSL

      options.ssl = merge {}, service.use.hadoop_core.options.ssl, options.ssl
      options.truststore_location ?= "#{options.conf_dir}/truststore"
      options.truststore_password ?= options.ssl.truststore.password

## Test

      options.ranger_install = service.use.ranger_hive[0].options.install if service.use.ranger_hive
      options.test = merge {}, service.use.test_user.options, options.test
      # Hive Server2
      options.hive_server2 = for srv in service.use.hive_server2
        fqdn: srv.options.fqdn
        hostname: srv.options.hostname
        hive_site: srv.options.hive_site
      options.spark_thrift_server = for srv in service.use.spark_thrift_server or []
        fqdn: srv.options.fqdn
        hostname: srv.options.hostname

## Wait

      options.wait_hive_server2 = service.use.hive_server2[0].options.wait
      options.wait_spark_thrift_server = service.use.spark_thrift_server.options.wait if service.use.spark_thrift_server
      options.wait_ranger_admin = service.use.ranger_admin.options.wait if service.use.ranger_admin

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
