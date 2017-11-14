
# MongoDB Repo Configure

    module.exports = (service) ->
      options = service.options

      options.source ?= null
      options.target ?= 'mongodb.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'mongodb*'
      options.download = service.nodes[0].fqdn is service.node.fqdn

## Dependencies

    path = require('path').posix
