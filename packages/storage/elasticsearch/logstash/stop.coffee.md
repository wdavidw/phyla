
# Logstash stop

This commands stops Logstash using the default service command.

    module.exports = header: 'Logstash Start', handler: ->
      @service.stop
        name: 'logstash'
