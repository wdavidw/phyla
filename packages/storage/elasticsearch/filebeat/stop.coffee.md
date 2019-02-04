
# Filebeat Stop

This commands stops Filebeat using the default service command.

    module.exports = header: 'Filebeat Stop', handler: ->
      @service.stop
        name: 'filebeat'
