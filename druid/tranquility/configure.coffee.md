
# Tranquility Configure

    module.exports = (service) ->
      options = service.options

## Identities

      options.group = merge {}, service.deps.druid.options.group, options.group
      options.user = merge {}, service.deps.druid.options.user, options.user

## Environment

      # Layout
      options.dir ?= '/opt/tranquility'
      options.pid_dir = service.deps.druid.options.pid_dir
      # Misc
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'

## Package

      options.version ?= "0.8.0"
      options.source ?= "http://static.druid.io/tranquility/releases/tranquility-distribution-#{druid.tranquility.version}.tgz"

## Dependencies

    {merge} = require '@nikita/core/lib/misc'
