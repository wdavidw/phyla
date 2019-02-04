
    module.exports =
      header: 'Solr Cloud Download'
      if: -> @contexts('@rybajs/metal/solr/cloud')[0]?.config.host is @config.host
      ssh: false
      handler: ->
        @file.cache
          source: @config.ryba.solr.cloud.source
          location: true
