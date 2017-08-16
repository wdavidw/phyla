
# HDP Repository

    module.exports =
      use: {}
      configure:
        'ryba/hdp/configure'
      commands:
        'install': ->
          options = @config.ryba.hdp
          @call 'ryba/hdp/install', options
        'prepare': ->
          options = @config.ryba.hdp
          @call 'ryba/hdp/prepare', options
