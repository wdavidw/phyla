
# Prometheus Montior Prepare

    module.exports = header: 'Prometheus JMX Exporter Prepare', handler: (options) ->

## Cache file

      @file.cache
        if: options.download
        header: "Standalone Jar #{options.version}"
        location: true
        ssh: null
        # md5: info.md5
        # sha256: info.jdk_sha256
      , "#{options.standalone_source}"
      @file.cache
        if: options.download
        header: "Agent Jar #{options.version}"
        location: true
        ssh: null
        # md5: info.md5
        # sha256: info.jdk_sha256
      , "#{options.agent_source}"
