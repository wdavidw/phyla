

## Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/mongodb/client', ['ryba', 'mongodb', 'client'], require('nikita/lib/misc').merge require('.').use,
        locale: key: ['locale']
        repo: key: ['ryba','mongodb','repo']
        config_servers: key: ['ryba', 'mongodb', 'configsrv']
      @config.ryba ?= {}
      @config.ryba.mongodb ?= {}
      options = @config.ryba.mongodb.client = service.options

## Dependencies

    migration = require 'masson/lib/migration'
    {merge} = require 'nikita/lib/misc'
