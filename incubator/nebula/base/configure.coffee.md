
# OpenNebula Front Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/incubator/nebula/base', ['nebula', 'base'], require('nikita/lib/misc').merge require('.').use, {}
      @config.ryba ?= {}
      options = @config.nebula.base = service.options

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
      options.user.comment ?= 'OpenNebula User'
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

## Keys

Private and public keys are respectively accessed through the "private\_key" 
and "public\_key" options. They are required and accept the following options:

* `content` (string)   
  The content of the key, required unless source is provided
* `source` (string)   
  The path to the file storing the key, required unless content is provided
* `source` (boolean)   
  Is the source available local or remotely (in case of an remote connection 
  over SSH), only apply if the "target" option is defined.

      options.private_key ?= {}
      throw Error "Required option: private_key.content or private_key.source" unless options.private_key.content or options.private_key.source
      options.public_key ?= {}
      throw Error "Required option: public_key.content or public_key.source" unless options.public_key.content or options.public_key.source

## Dependencies

    path = require 'path'
    migration = require 'masson/lib/migration'
