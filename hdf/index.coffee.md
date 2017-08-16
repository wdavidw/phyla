
# HDF Repository

    module.exports =
      use: {}
      configure:
        'ryba/hdf/configure'
      commands:
        'install': ->
          options = @config.ryba.hdf
          @call 'ryba/hdf/install', options
        'prepare': ->
          options = @config.ryba.hdf
          @call 'ryba/hdf/prepare', options
