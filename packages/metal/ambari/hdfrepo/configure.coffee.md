
# Ambari Repo Configuration

    module.exports = ({options}) ->
      
      options.source ?= null
      options.target ?= 'ambari.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'ambari*'

## Dependencies

    path = require('path').posix
