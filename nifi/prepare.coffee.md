
# NiFi Prepare

Download the additional jars

    module.exports =
      header: 'NiFi Prepare'
      if: -> @contexts('ryba/nifi')[0]?.config.host is @config.host
      handler: ->
        @file.cache
          ssh: null
          source: "#{options.logback.core.source}"
          location: true
        @file.cache
          ssh: null
          source: "#{options.logback.classic.source}"
          location: true
        @file.cache
          ssh: null
          source: "#{options.logback.access.source}"
          location: true
        @file.cache
          ssh: null
          source: "#{options.logback.socketappender.source}"
          location: true
