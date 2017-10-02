
# Open Nebula Node Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/incubator/nebula/node', ['nebula', 'node'], require('nikita/lib/misc').merge require('.').use, {}
      @config.ryba ?= {}
      options = @config.nebula.node = service.options
      
      # throw Error "Required option: repo" unless options.repo
      # throw Error "Required option: server_public_key" unless options.server_public_key
      # options.server_public_key = options.server_public_key
      options.server_host = options.server_host

## Repository

      options.repo ?= {}
      options.repo.source ?= path.resolve __dirname, '../resources/opennebula.repo'
      options.repo.local ?= true
      options.repo.target ?= 'opennebula.repo'
      options.repo.target = path.posix.resolve '/etc/yum.repos.d', options.repo.target
      options.repo.replace ?= null

## Dependencies

    path = require 'path'
    migration = require 'masson/lib/migration'
