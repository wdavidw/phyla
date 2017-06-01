
# HDP Repo Prepare
Download the hdp.repo file if available

    module.exports = header: 'HDP Repo Prepare', handler: ->
      options = @config.ryba.hdp
      @file.cache
        if: @contexts('ryba/hdp')[0].config.host is @config.host
        ssh: null
        location: true
        source: options.repo
