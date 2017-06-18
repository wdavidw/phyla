
# HDP Install

    module.exports = header: 'HDP Install', handler: (options) ->
      options = @config.ryba.hdp
      @tools.repo
        if: options.source?
        header: 'Repository'
        source: options.source
        target: options.target
        replace: options.replace
        update: true
