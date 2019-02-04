
# Ranger Admin Status

Check if Ranger Admin is started

    module.exports = header: 'Ranger Admin Status', handler: ->
      @service.status 'ranger-admin'
