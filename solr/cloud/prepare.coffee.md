
    module.exports = 
      header: 'Solr Cloud Download'
      if: -> @contexts('ryba/solr/cloud')[0]?.config.host is @config.host
      handler: ->
        @file.cache
          ssh: null
          source: @config.ryba.solr.cloud.source
          location: true
