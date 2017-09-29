
# Solr Status

    module.exports = header: 'Solr Cloud Status', handler: ->
      @service.status
        name: 'solr'
        code_skipped: 1
