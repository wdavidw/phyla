
# Elasticsearch Start

This commands starts Elastic Search using the default service command.

    module.exports = header: 'ES Start', handler: ->
      @service.start
        name: 'elasticsearch'
