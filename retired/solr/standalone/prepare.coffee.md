
    module.exports =
      header: 'Solr Download'
      if: -> @contexts('ryba/solr/standalone')[0]?.config.host is @config.host
      ssh: false
      handler: ->
        @file.cache
          source: @config.ryba.solr.single.source
          location: true
