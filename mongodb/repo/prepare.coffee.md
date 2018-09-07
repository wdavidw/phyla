
# MongoDB Repository Prepare

Download the mongodb.repo file if available

    module.exports =
      header: 'MongoDB Repo Prepare'
      ssh: false
      handler: ({options}) ->
        @file.cache
          if: options.download
          location: true
          source: options.source
