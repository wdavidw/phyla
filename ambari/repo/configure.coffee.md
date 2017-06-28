
# Ambari Repo Configuration

    module.exports = ->
      @config.ryba.ambari ?= {}
      options = @config.ryba.ambari.repo ?= {}
      options.source ?= null
      options.target ?= 'ambari.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'ambari*'

## Dependencies

    path = require('path').posix
