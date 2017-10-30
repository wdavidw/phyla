
# MongoDB Repo Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/mongodb/repo', ['ryba', 'mongodb','repo'], {}
      @config.ryba ?= {}
      @config.ryba.mongodb ?= {}
      options = @config.ryba.mongodb.repo = service.options

      options.source ?= null
      options.target ?= 'mongodb.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'mongodb*'
      options.download = service.nodes[0].fqdn is service.node.fqdn

## Dependencies

    path = require('path').posix
    migration = require 'masson/lib/migration'
