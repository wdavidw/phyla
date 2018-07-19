# Ranger HiveServer2 Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        hive_hcatalog: module: 'ryba/hive/hcatalog', required: true
        hive_server2: module: 'ryba/hive/server2', local: true, required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs'
        ranger_hive: module: 'ryba/ranger/plugins/hiveserver2'
      configure:
        'ryba/ranger/plugins/hiveserver2/configure'
      plugin: (options) ->
        @before
          action: ['service', 'start']
          name: 'hive-server2'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/ranger/plugins/hiveserver2/install', options.original
        # @after 'ryba/hive/server2/install', ->
        #   @call 'ryba/ranger/plugins/hiveserver2/install', options
