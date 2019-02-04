
# Atlas Metadata Server Status

Check if Atlas Server is started

    module.exports = header: 'Atlas Status', handler: ->
      @service.status 'atlas-metadata-server'
