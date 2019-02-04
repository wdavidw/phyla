
# Tranquility Start

This commands starts Elastic Search using the default service command.

    module.exports = header: 'Tranquility Start', handler: ->
      @service.start
        name: 'tranquility'
