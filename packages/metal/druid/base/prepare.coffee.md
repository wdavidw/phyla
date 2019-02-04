
# Druid Prepare

Download the Druid package.

    module.exports =
      header: 'Druid Prepare'
      if: (options) -> options.prepare
      ssh: false
      handler: (options) ->
        @file.cache
          header: 'Druid Package'
          ssh: false
          source: "#{options.source}"
        @file.cache
          header: 'MySQL Extension'
          ssh: false
          source: "#{options.source_mysql_extension}"
