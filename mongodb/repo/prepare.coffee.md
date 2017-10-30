
# MongoDB Repository Prepare

Download the mongodb.repo file if available

    module.exports =
      header: 'MongoDB Repo Prepare'
      ssh: null
      handler: (options) ->
        if options.download
          @file.cache
            location: true
            source: options.source
