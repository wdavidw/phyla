
# Collectd Exporter Prepare

    module.exports =
      header: 'Collectd Exporter Prepare',
      ssh: false
      handler: ({options}) ->
        @file.cache
          if: options.download
          location: true
          # md5: info.md5
          # sha256: info.jdk_sha256
        , "#{options.source}"
