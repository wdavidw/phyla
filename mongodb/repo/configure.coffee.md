
# MongoDB Repo Configure

    module.exports = (service) ->
      options = service.options

      options.source ?= null
      options.target ?= 'mongodb.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'mongodb*'
      options.download = service.instances[0].node.fqdn is service.node.fqdn

## Dependencies

    path = require('path').posix
