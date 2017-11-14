
# Grafana Repository Configure

    module.exports = (service) ->
      options = service.options

## Configuration

      options.source ?= null
      options.target ?= 'grafana.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'grafana*'
      options.download = service.nodes[0].fqdn is service.node.fqdn

## Dependencies

    path = require('path').posix
