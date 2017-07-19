
# JanusGraph Prepare

Download the package.

    module.exports =
      header: 'JanusGraph Prepare'
      if: -> @contexts('ryba/janusgraph')[0]?.config.host is @config.host
      handler: ->
        @file.cache
          ssh: null
          source: "#{@config.ryba.janusgraph.source}"
