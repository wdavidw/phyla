
# Filebeat Prepare

    module.exports = header: 'Filebeat Prepare', handler: (options) ->
      @file.cache
        ssh: null
        source: "#{options.source}"
