
# MongoDB Config Server Status

    module.exports = header: 'MongoDB Config Server Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (options) ->

## Status

      @service.status name: 'mongod-config-server'
