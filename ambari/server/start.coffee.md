
# Ambari Server start

Ambari server is started with the service's syntax command.

    module.exports = header: 'Ambari Server Start', handler: ->
      @service.start
        name: 'ambari-server'
