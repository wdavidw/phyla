
# Logstash Status

This commands checks the status of Logstash (STARTED, STOPPED)

    module.exports = header: 'Logstash Status', handler: ->
      @service.status name: 'logstash'
