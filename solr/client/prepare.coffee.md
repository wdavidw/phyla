
    module.exports =
      header: 'Solr Client Download'
      handler: ->
        @file.cache
          ssh: null
          source: @config.ryba.solr.client.source
          location: true
