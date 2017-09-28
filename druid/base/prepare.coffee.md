
# Druid Prepare

Download the Druid package.

    module.exports = header: 'Druid Prepare', handler: (options) ->
      @file.cache
        ssh: null
        source: "#{options.source}"
      @file.cache
        ssh: null
        source: "#{options.source_mysql_extension}"
