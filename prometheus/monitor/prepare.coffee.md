
# Prometheus Montior Prepare

    module.exports =
      header: 'Prometheus Monitor Prepare'
      ssh: false
      handler: ({options}) ->
        @file.cache
          if: options.download
          header: "Binary #{options.version}"
          location: true
          # md5: info.md5
          # sha256: info.jdk_sha256
        , "#{options.source}"
