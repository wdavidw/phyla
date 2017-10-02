
# Open Nebula Front Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/incubator/nebula/front', ['nebula', 'front'], require('nikita/lib/misc').merge require('.').use,
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
