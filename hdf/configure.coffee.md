
# HDF Repository Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/hdf', ['ryba', 'hdf'], {}
      options = @config.ryba.hdf ?= service.options
      
      options.source ?= null
      options.target ?= 'hdf.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'hdf*'

## Dependencies

    path = require('path').posix
    migration = require 'masson/lib/migration'
