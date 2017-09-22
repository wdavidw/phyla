
# Nifi with Ambari

    module.exports =
      use:
        ssl: module: 'masson/core/ssl'
        hdf: module: 'ryba/hdf', local: true
        # ambari: 'ryba/ambari/hdfagent'
      configure: 'ryba/ambari/nifi/configure'
      commands:
        'prepare': ->
          options = @config.ryba.ambari.nifi
          active = @contexts('ryba/ambari/nifi')[0]?.config.host is @config.host
          @call 'ryba/ambari/nifi/prepare', if: active, options
        'install': ->
          options = @config.ryba.ambari.nifi
          @call 'ryba/ambari/nifi/install', options
