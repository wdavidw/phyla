
# Filebeat Status

This commands checks the status of Filebeat (STARTED, STOPPED)

    module.exports = header: 'Filebeat Status', handler: ->
      @service.status name: 'filebeat'
