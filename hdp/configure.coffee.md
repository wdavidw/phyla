
# HDP Repository Configure

    module.exports = (service) ->
      options = service.options
      
## Configuration

      options.source ?= null
      options.target ?= 'hdp.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'hdp*'
      options.download = service.nodes[0].fqdn is service.node.fqdn

## Dependencies

    path = require('path').posix
