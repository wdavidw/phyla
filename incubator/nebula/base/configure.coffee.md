
# Open Nebula Front Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/incubator/nebula/base', ['nebula'], require('nikita/lib/misc').merge require('.').use, {}
      @config.ryba ?= {}
      options = @config.nebula = service.options

## Identties

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'oneadmin'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'oneadmin'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.comment ?= 'Open Nebula User'
      options.user.home ?= '/var/lib/one'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= true

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
