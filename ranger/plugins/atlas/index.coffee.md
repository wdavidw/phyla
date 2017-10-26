# Ranger HiveServer2 Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        atlas: module: 'ryba/atlas', local: true, required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs'
        hdfs_client: module: 'ryba/hadoop/hdfs_client'
      plugin: ->
        options = @config.ryba.ranger.atlas
        @before
          type: ['service', 'start']
          name: 'atlas-metadata-server'
        , ->
          @call 'ryba/ranger/plugins/atlas/install', options
      configure:
        'ryba/ranger/plugins/atlas/configure'
