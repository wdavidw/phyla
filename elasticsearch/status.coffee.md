
# Elasticsearch Status

This commands checks the status of ElasticSearch (STARTED, STOPPED)

    module.exports = header: 'ES Status', handler: ->
      @service.status name: 'elasticsearch'
