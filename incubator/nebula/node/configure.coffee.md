
# OpenNebula Node Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/incubator/nebula/node', ['nebula', 'node'], require('nikita/lib/misc').merge require('.').use,
        nebula_base: key: ['ryba', 'nebula', 'base']
      @config.ryba ?= {}
      options = @config.nebula.node = service.options
      
      # throw Error "Required option: repo" unless options.repo
      # throw Error "Required option: server_public_key" unless options.server_public_key
      # options.server_public_key = options.server_public_key
      options.server_host = options.server_host

## Dependencies

    path = require 'path'
    migration = require 'masson/lib/migration'
