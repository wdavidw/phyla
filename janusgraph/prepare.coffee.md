
# JanusGraph Prepare

Download the package.

    module.exports =
      header: 'JanusGraph Prepare'
      if: -> @contexts('ryba/janusgraph')[0]?.config.host is @config.host
      ssh: false
      handler: (options) ->
        @file.cache
          source: "#{options.source}"
