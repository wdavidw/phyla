
# HDP Repository Prepare

Download the hdp.repo file if available

    module.exports =
      header: 'HDP Repo Prepare'
      ssh: null
      handler: (options) ->
        if options.download
          @file.cache
            location: true
            source: options.source
