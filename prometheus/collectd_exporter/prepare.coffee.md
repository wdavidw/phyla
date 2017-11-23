
# Collectd Exporter Prepare

    module.exports = header: 'Collectd Exporter Prepare', handler: (options) ->

## Cache file

      @file.cache
        if: options.download
        location: true
        ssh: null
        # md5: info.md5
        # sha256: info.jdk_sha256
      , "#{options.source}"
