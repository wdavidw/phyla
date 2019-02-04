
# Grafana Repository Configure

    module.exports = (service) ->
      options = service.options

## Configuration

      options.source ?= null
      options.target ?= 'grafana.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'grafana*'
      options.prepare = service.node.id is service.instances[0].node.id

## Dependencies

    path = require('path').posix
