
# HDF Repository Prepare

Download the hdf.repo file if available

    module.exports = 
      header: 'HDF Repo Prepare'
      if: @contexts('ryba/hdf')[0].config.host is @config.host
      ssh: false
      handler: (options) ->
        @file.cache
          location: true
          source: options.source
