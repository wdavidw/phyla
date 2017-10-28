
# HDP Repository Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/grafana/repo', ['ryba', 'grafana', 'repo'], {}
      @config.ryba.grafana ?= {}
      options = @config.ryba.grafana.repo = service.options

## Configuration
      options.source ?= null
      options.target ?= 'grafana.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'grafana*'

## Dependencies

    path = require('path').posix
    migration = require 'masson/lib/migration'
