
# HDP Repository Prepare

Download the hdp.repo file if available

    module.exports =
      header: 'HDP Repo Prepare'
      ssh: false
      handler: (options) ->
        if options.download
          @file.cache
            location: true
            source: options.source
