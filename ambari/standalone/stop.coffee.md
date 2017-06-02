
# Ambari Server Stop

    module.exports = header: 'Ambari Standalone Stop', label_true: 'STOPPED', handler: ->
        @service.stop
          name: 'ambari-server'
