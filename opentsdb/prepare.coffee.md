
# OpenTSDB Prepare

Download the rpm package.

    module.exports =
      header: 'OpenTSDB Prepare'
      if: -> @contexts('ryba/opentsdb')[0]?.config.host is @config.host
      ssh: false
      handler: ->
        @file.cache
          source: "#{@config.ryba.opentsdb.source}"
          location: true
