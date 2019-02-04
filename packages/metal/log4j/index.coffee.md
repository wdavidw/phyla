
# Hadoop Log4j

Configure Log4j. Does not write anyfile.
    
    # migration: lucasbak
    # this module is a helper to isolate log4j configuration
    # other module does read only from it
    
    module.exports =
      deps: {}
      configure: (service) ->
        options = service.options

## Configuration
      
        throw Error 'Missing ryba.log4j.remote_host' unless options.remote_host?
        throw Error 'Missing ryba.log4j.remote_port' unless options.remote_port?
        options.properties ?= {}

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
