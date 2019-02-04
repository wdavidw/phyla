
# Ambari Server Stop

    module.exports = header: 'Ambari Standalone Stop', handler: ->
        @service.stop
          name: 'ambari-server'
