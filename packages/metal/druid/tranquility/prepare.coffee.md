
# Druid Tranquility Prepare

Download the Tranquility package.

    module.exports = header: 'Druid Tranquility Prepare', handler: ->
      {druid} = @config.ryba
      @file.cache
        ssh: false
        source: "#{druid.tranquility.source}"
