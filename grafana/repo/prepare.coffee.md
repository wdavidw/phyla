
# Grafana Repository Prepare

Download the grafana.repo file if available

    module.exports =
      header: 'Grafana Repo Prepare'
      ssh: null
      handler: (options) ->
        if options.download
          @file.cache
            location: true
            source: options.source
