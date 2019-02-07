
# Ambari Repo Configuration

    module.exports = (service) ->
      service = migration.call @, service, '@rybajs/metal/ambari/hdfrepo', ['ryba', 'ambari', 'hdfrepo'], require('@nikitajs/core/lib/misc').merge require('.').use, {}
      @config.ryba ?= {}
      @config.ryba.ambari ?= {}
      options = @config.ryba.ambari.hdfrepo = service.options
      
      options.source ?= null
      options.target ?= 'ambari.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'ambari*'

## Dependencies

    path = require('path').posix
    migration = require 'masson/lib/migration'
