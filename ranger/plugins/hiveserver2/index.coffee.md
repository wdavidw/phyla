# Ranger HiveServer2 Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hive_hcatalog: module: 'ryba/hive/hcatalog', required: true
        hive_server2: module: 'ryba/hive/server2', local: true, required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs', local: true, required: true
        ranger_hive: module: 'ryba/ranger/plugins/hiveserver2'
      configure:
        'ryba/ranger/plugins/hiveserver2/configure'
      plugin: ->
        options = @config.ryba.ranger.hive
        @before
          type: ['service', 'start']
          name: 'hive-server2'
        , ->
          @call 'ryba/ranger/plugins/hiveserver2/install', options
        # @after 'ryba/hive/server2/install', ->
        #   @call 'ryba/ranger/plugins/hiveserver2/install', options
