
# OpenTSDB Prepare

Download the rpm package.

    module.exports =
      header: 'OpenTSDB Prepare'
      ssh: false
      handler: (options) ->
        @file.cache
          source: "#{options.source}"
          location: true
