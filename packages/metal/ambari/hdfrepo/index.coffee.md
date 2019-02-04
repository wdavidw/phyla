
# Ambari Repo

    module.exports =
      use: {}
      configure:
        '@rybajs/metal/ambari/hdfrepo/configure'
      commands:
        'install': ->
          options = @config.ryba.ambari.hdfrepo
          @call '@rybajs/metal/ambari/repo/install', options
