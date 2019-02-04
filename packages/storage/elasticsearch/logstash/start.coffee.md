
# Logstash Start

This commands starts Logstash using the default service command.

    module.exports = header: 'Logstash Start', handler: ->
      @service.start
        name: 'logstash'
