
# Ambari Repo

    module.exports =
      use: {}
      configure:
        'ryba/ambari/repo/configure'
      commands:
        'install': ->
          options = @config.ryba.ambari.hdfrepo
          @call 'ryba/ambari/repo/install', options
