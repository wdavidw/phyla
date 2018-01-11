
# Logstash Prepare

    module.exports = header: 'Logstash Prepare', handler: (options) ->
      @file.cache
        ssh: null
        source: "#{options.source}"
