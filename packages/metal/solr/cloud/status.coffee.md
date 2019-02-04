
# Solr Status

    module.exports = header: 'Solr Cloud Status', handler: (options) ->
      @service.status 'solr'
