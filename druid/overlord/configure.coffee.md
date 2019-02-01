
# Druid Overlord Configure

Example:

```json
{
  "jvm": {
    "xms": "3g",
    "xmx": "3g"
  }
}
```

    module.exports = (service) ->
      options = service.options

## Identities

      options.group = merge {}, service.deps.druid.options.group, options.group
      options.user = merge {}, service.deps.druid.options.user, options.user

## Environment

      # Layout
      options.dir = service.deps.druid.options.dir
      options.log_dir = service.deps.druid.options.log_dir
      options.pid_dir = service.deps.druid.options.pid_dir
      # Miscs
      options.version = service.deps.druid.options.version
      options.timezone = service.deps.druid.options.timezone
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false

## Java

      options.jvm ?= {}
      options.jvm.xms ?= '3g'
      options.jvm.xmx ?= '3g'

## Configuration

      options.runtime ?= {}
      options.runtime['druid.service'] ?= 'druid/overlord'
      options.runtime['druid.port'] ?= '8090'
      options.runtime['druid.indexer.queue.startDelay'] ?= 'PT30S'
      options.runtime['druid.indexer.runner.type'] ?= 'remote'
      options.runtime['druid.indexer.storage.type'] ?= 'metadata'

## Kerberos

      options.krb5_service = merge {}, service.deps.druid.options.krb5_service, options.krb5_service

## Wait

      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.deps.druid_overlord
        host: srv.node.fqdn
        port: srv.options.runtime?['druid.port'] or '8090'

## Dependencies

    {merge} = require '@nikita/core/lib/misc'
