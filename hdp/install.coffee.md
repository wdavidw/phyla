
# HDP Install

    module.exports = header: 'HDP Install', handler: (options) ->
      options = @config.ryba.hdp
      @tools.repo
        if: options.repo?
        header: 'Repository'
        source: options.source
        target: options.target
        replace: options.replace
        update: true
