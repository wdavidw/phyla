
# NiFi Prepare

Download the additional jars

    module.exports =
      header: 'NiFi Prepare'
      if: -> @contexts('@rybajs/metal/nifi')[0]?.config.host is @config.host
      ssh: false
      handler: ->
        @file.cache
          source: "#{options.logback.core.source}"
          location: true
        @file.cache
          source: "#{options.logback.classic.source}"
          location: true
        @file.cache
          source: "#{options.logback.access.source}"
          location: true
        @file.cache
          source: "#{options.logback.socketappender.source}"
          location: true
