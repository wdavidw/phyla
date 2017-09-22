
# Ambari Repo Configuration

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/ambari/repo', ['ryba', 'ambari', 'repo'], require('nikita/lib/misc').merge require('.').use, {}
      @config.ryba ?= {}
      @config.ryba.ambari ?= {}
      options = @config.ryba.ambari.repo = service.options
      
      options.source ?= null
      options.target ?= 'ambari.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'ambari*'

## Dependencies

    path = require('path').posix
    migration = require 'masson/lib/migration'
