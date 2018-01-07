
# Druid Prepare

Download the Druid package.

    module.exports = header: 'Druid Prepare', handler: (options) ->
      @file.cache
        ssh: false
        source: "#{options.source}"
      @file.cache
        ssh: false
        source: "#{options.source_mysql_extension}"
