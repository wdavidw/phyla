
# Ambari Server Stop

    module.exports = header: 'Ambari Server Stop', handler: ->
        @service.stop
          name: 'ambari-server'
