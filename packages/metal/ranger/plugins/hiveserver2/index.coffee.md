# Ranger HiveServer2 Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        hive_hcatalog: module: '@rybajs/metal/hive/hcatalog', required: true
        hive_server2: module: '@rybajs/metal/hive/server2', local: true, required: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true, required: true
        ranger_hdfs: module: '@rybajs/metal/ranger/plugins/hdfs'
        ranger_hive: module: '@rybajs/metal/ranger/plugins/hiveserver2'
      configure:
        '@rybajs/metal/ranger/plugins/hiveserver2/configure'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'hive-server2'
        , ->
          @call '@rybajs/metal/ranger/plugins/hiveserver2/install', options
        # @after '@rybajs/metal/hive/server2/install', ->
        #   @call '@rybajs/metal/ranger/plugins/hiveserver2/install', options
