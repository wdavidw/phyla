
# Prometheus Montior Prepare

    module.exports = header: 'Prometheus Monitor Prepare', handler: (options) ->

## Cache file

      @file.cache
        if: options.download
        header: "Binary #{options.version}"
        location: true
        ssh: null
        # md5: info.md5
        # sha256: info.jdk_sha256
      , "#{options.source}"
