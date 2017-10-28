
# Grafana Prepare

    module.exports = header: 'Grafana Prepare', handler: (options) ->

## Cache file

      @file.cache
        if: options.download
        header: "Grafana RPM "
        location: true
        ssh: null
        # md5: info.md5
        # sha256: info.jdk_sha256
      , "#{options.source}"
