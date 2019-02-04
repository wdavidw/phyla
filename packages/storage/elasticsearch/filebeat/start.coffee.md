
# Filebeat Start

This commands starts Filebeat using the default service command.

    module.exports = header: 'Filebeat Start', handler: ->
      @service.start
        name: 'filebeat'
