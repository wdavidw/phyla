
# NiFi Stop

    module.exports = header: 'NiFi Stop', handler: ->
      @service.stop name: 'nifi'
