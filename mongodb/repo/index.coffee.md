
# HDP Repository

    module.exports =
      use: {}
      configure:
        'ryba/mongodb/repo/configure'
      commands:
        'install': ->
          options = @config.ryba.mongodb.repo
          @call 'ryba/mongodb/repo/install', options
        'prepare': ->
          options = @config.ryba.mongodb.repo
          @call 'ryba/mongodb/repo/prepare', options
