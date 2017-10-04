
# OpenNebula Front Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/incubator/nebula/front', ['nebula', 'front'], require('nikita/lib/misc').merge require('.').use,
        nebula_base: key: ['ryba', 'nebula', 'base']
        nebula_node: key: ['ryba', 'nebula', 'node']
      @config.ryba ?= {}
      options = @config.nebula.front = service.options

## Validation

      throw Error "Required option: password" unless options.password

## Environment

      # Layout
      options.log_dir ?= '/var/log/one'
      # Where the gem are stored local after being downloaded in prepare
      options.cache_dir ?= '.' # local dir
      options.gem_dir ?= path.resolve options.cache_dir, 'nebula', 'gems'
      # Misc
      options.clean_logs ?= false

## Normalization

      options.nebula_node_hosts = service.use.nebula_node.map (srv) -> srv.node.fqdn

## Dependencies

    path = require 'path'
    migration = require 'masson/lib/migration'
