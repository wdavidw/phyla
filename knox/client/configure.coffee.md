
# Knox Client Configure


## Configure

    module.exports = (service) ->
      options = service.options

## Test

      # is ranger enabled or not for policies management
      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin
      options.ranger_install = service.deps.ranger_knox[0].options.install if service.deps.ranger_knox
      options.test = merge {}, service.deps.knox_server[0].options.test, options.test
      # Knox Server
      options.knox_gateway = for srv in service.deps.knox_server
        fqdn: srv.options.fqdn
        hostname: srv.options.hostname
        gateway_site: srv.options.gateway_site
        topologies: srv.options.topologies
          
# Wait

      options.wait_knox_server = service.deps.knox_server[0].options.wait

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
