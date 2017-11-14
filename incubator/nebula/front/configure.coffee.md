
# OpenNebula Front Configure

    module.exports = (service) ->
      options = service.options

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

      options.nebula_node_hosts = service.deps.nebula_node.map (srv) -> srv.node.fqdn

## Dependencies

    path = require 'path'
