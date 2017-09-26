
# MongoDB Config Server Start

    module.exports = header: 'MongoDB Config Server Start', label_true: 'STARTED', handler: (options) ->

## Start

      @service.start name: 'mongod-config-server'

## Dependencies

    path = require 'path'
