
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
      hs2_ctxs = @contexts 'ryba/hive/server2'
      hcat_ctxs = @contexts 'ryba/hive/hcatalog'
      throw Error "No Hive Server2 server declared" unless hs2_ctxs.length
      throw Error "No Hive HCatalog declared" unless hcat_ctxs.length
      @config.ryba.hive ?= {}
      options = @config.ryba.hive.beeline ?= {}

## Identities

      options.user = merge hs2_ctxs[0].config.ryba.hive.user, options.user
      options.group = merge hs2_ctxs[0].config.ryba.hive.group, options.group

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive/conf'
      # Opts and Java
      options.opts = ""
      options.heapsize = 1024
      options.aux_jars ?= hcat_ctxs[0].config.ryba.hive.hcatalog.aux_jars

## Import HiveServer2 Configuration

      options.site ?= {}
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
      ] then options.site[property] ?= hs2_ctxs[0].config.ryba.hive.server2.site[property]

## Configure SSL

      options.truststore_location ?= "#{options.conf_dir}/truststore"
      options.truststore_password ?= "ryba123"

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
