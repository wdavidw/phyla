
# Solr Status

    module.exports = header: 'Solr Status', handler: ->
      @service.status name: 'solr'
