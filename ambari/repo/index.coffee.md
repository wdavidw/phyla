
# Ambari Repo

    module.exports =
      use: {}
      configure:
        'ryba/ambari/repo/configure'
      commands:
        'install': ->
          options = @config.ryba.ambari.repo
          @call 'ryba/ambari/repo/install', options
