
# Shinken Arbiter Status

    module.exports = header: 'Shinken Arbiter Status', handler: ->
      @service.status name: 'shinken-arbiter'
