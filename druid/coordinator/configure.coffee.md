
# Druid Coordinator Configure

Example:

```json
{
  "jvm": {
    "xms": "3g",
    "xmx": "3g"
  }
}
```

    module.exports = ->
      service = migration.call @, service, 'ryba/druid/coordinator', ['ryba', 'druid', 'coordinator'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        zookeeper_server: key: ['ryba', 'zookeeper']
        # hdfs_client: key: ['ryba', 'hdfs_client']
        druid: key: ['ryba', 'druid', 'base']
        druid_coordinator: key: ['ryba', 'druid', 'coordinator']
      @config.ryba.druid ?= {}
      options = @config.ryba.druid.coordinator = service.options

## Identities

      options.group = merge {}, service.use.druid.options.group, options.group
      options.user = merge {}, service.use.druid.options.user, options.user

## Environnment

      # Layout
      options.dir = service.use.druid.options.dir
      options.log_dir = service.use.druid.options.log_dir
      options.pid_dir = service.use.druid.options.pid_dir
      # Misc
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      options.version ?= service.use.druid.options.version
      options.timezone = service.use.druid.options.timezone
      options.clean_logs ?= false

## Java

      options.jvm ?= {}
      options.jvm.xms ?= '3g'
      options.jvm.xmx ?= '3g'

## Configuration

      options.runtime ?= {}
      options.runtime['druid.service'] ?= 'druid/coordinator'
      options.runtime['druid.port'] ?= '8081'
      options.runtime['druid.coordinator.startDelay'] ?= 'PT30S'
      options.runtime['druid.coordinator.period'] ?= 'PT30S'

## Kerberos

      options.krb5_service = merge {}, service.use.druid.options.krb5_service, options.krb5_service

## Wait

      options.wait_zookeeper_server = service.use.zookeeper_server[0].options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.use.druid_coordinator
        host: srv.node.fqdn
        port: srv.options.runtime?['druid.port'] or '8081'

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
