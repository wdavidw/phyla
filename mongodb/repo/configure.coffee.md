
# HDP Repository Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/mongodb/repo', ['ryba', 'mongodb','repo'], {}
      options = @config.ryba.mongodb.repo = service.options
      options.source ?= null
      options.target ?= 'mongodb.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'mongodb*'

## Dependencies

    path = require('path').posix
    migration = require 'masson/lib/migration'
