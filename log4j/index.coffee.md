
# Hadoop Log4j

Configure Log4j. Does not write anyfile.
    
    # migration: lucasbak
    # this module is a helper to isolate log4j configuration
    # other module does read only from it
    
    module.exports =
      use: {}
      configure: (service) ->
        service = migration.call @, service, 'ryba/metrics', ['ryba', 'log4j'], require('nikita/lib/misc').merge require('.').use,
          {}
        options = @config.ryba.log4j = service.options

## Configuration
      
        throw Error 'Missing ryba.log4j.remote_host' unless options.remote_host?
        throw Error 'Missing ryba.log4j.remote_port' unless options.remote_port?
        options.properties ?= {}

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
