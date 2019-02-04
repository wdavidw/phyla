
# HDP Repository Configure

    module.exports = (service) ->
      options = service.options
      
## Configuration

      options.source ?= null
      options.target ?= 'hdp.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'hdp*'
      options.download = service.instances[0].node.fqdn is service.node.fqdn

## Dependencies

    path = require('path').posix
