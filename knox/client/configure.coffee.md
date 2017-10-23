
# Knox Client Configure


## Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/knox/client', ['ryba', 'knox'], require('nikita/lib/misc').merge require('.').use,
        knox_server: key: ['ryba', 'knox']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        ranger_knox: key: ['ryba', 'ranger', 'knox']
      @config.ryba ?= {}
      options = @config.ryba.knox = service.options

## Test

      # is ranger enabled or not for policies management
      options.ranger_admin ?= service.use.ranger_admin.options.admin if service.use.ranger_admin
      options.ranger_install = service.use.ranger_knox[0].options.install if service.use.ranger_knox
      options.test = merge {}, service.use.knox_server[0].options.test, options.test
      # Knox Server
      options.knox_gateway = for srv in service.use.knox_server
        fqdn: srv.options.fqdn
        hostname: srv.options.hostname
        gateway_site: srv.options.gateway_site
        topologies: srv.options.topologies
          
# Wait

      options.wait_knox_server = service.use.knox_server[0].options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
