
# HDP Repository Prepare

Download the hdp.repo file if available

    module.exports =
      header: 'MongoDB Repo Prepare'
      if: @contexts('ryba/mongodb/repo')[0].config.host is @config.host
      ssh: null
      handler: (options) ->
        @file.cache
          location: true
          source: options.source
