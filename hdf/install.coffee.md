
# HDF Install

    module.exports = header: 'HDF Install', handler: (options) ->
      options = @config.ryba.hdf
      @tools.repo
        if: options.repo?
        header: 'Repository'
        source: options.repo
        target: options.target
        replace: options.replace
        update: true
