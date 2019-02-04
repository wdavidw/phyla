
# Nifi with Ambari

    module.exports =
      use:
        ssl: module: 'masson/core/ssl'
        hdf: module: '@rybajs/metal/hdf', local: true
        # ambari: '@rybajs/metal/ambari/hdfagent'
      configure: '@rybajs/metal/ambari/nifi/configure'
      commands:
        'prepare': ->
          options = @config.ryba.ambari.nifi
          active = @contexts('@rybajs/metal/ambari/nifi')[0]?.config.host is @config.host
          @call '@rybajs/metal/ambari/nifi/prepare', if: active, options
        'install': ->
          options = @config.ryba.ambari.nifi
          @call '@rybajs/metal/ambari/nifi/install', options
