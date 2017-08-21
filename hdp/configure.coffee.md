
# HDP Repository Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/hdp', ['ryba', 'hdp'], {}
      options = @config.ryba.hdp = service.options
      
      options.source ?= null
      options.target ?= 'hdp.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'hdp*'

## Dependencies

    path = require('path').posix
    migration = require 'masson/lib/migration'
