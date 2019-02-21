
# Ambari Agent Start

Ambari Agent is started with the service's syntax command.

    module.exports = header: 'Ambari Agent Start', handler: ->

Start the service

      @service.start
        name: 'ambari-agent'
