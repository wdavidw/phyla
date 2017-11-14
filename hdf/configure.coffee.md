
# HDF Repository Configure

    module.exports = (service) ->
      options = service.options
      
      options.source ?= null
      options.target ?= 'hdf.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'hdf*'

## Dependencies

    path = require('path').posix
