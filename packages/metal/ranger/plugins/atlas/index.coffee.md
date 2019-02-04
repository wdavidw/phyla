# Ranger HiveServer2 Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        atlas: module: '@rybajs/metal/atlas', local: true, required: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true, required: true
        ranger_hdfs: module: '@rybajs/metal/ranger/plugins/hdfs'
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'atlas-metadata-server'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call '@rybajs/metal/ranger/plugins/atlas/install', options.original
      configure:
        '@rybajs/metal/ranger/plugins/atlas/configure'
