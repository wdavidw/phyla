
    module.exports =
      header: 'Solr Client Prepare'
      ssh: false
      handler: ->
        @file.cache
          source: @config.ryba.solr.client.source
          location: true
