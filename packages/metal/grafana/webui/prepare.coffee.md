
# Grafana Prepare

    module.exports = header: 'Grafana Prepare', ssh: false, handler: ({options}) ->

## Cache file

      @file.cache
        if: options.download
        header: 'RPM'
        location: true
        # md5: info.md5
        # sha256: info.jdk_sha256
      , "#{options.source}"
