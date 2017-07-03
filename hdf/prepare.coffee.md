
# HDF Repository Prepare

Download the hdf.repo file if available

    module.exports = header: 'HDF Repo Prepare', handler: ->
      options = @config.ryba.hdf
      @file.cache
        if: @contexts('ryba/hdf')[0].config.host is @config.host
        ssh: null
        location: true
        source: options.source
