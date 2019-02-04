
# Elasticsearch Stop

This commands stops Elasticsearch service.

    module.exports = header: 'ES Stop', handler: ->
      @service.stop
        name: 'elasticsearch'
        if_exists: '/etc/init.d/elasticsearch'
