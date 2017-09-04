# Ranger HBase Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hbase_master: module: 'ryba/hbase/master', local: true, required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
      configure:
        'ryba/ranger/plugins/hbase/configure'
      plugin: ->
        options = @config.ryba.ranger.hdfs_plugin
        @before
          type: ['service', 'start']
          name: 'hadoop-hdfs-namenode'
        , ->
          @call 'ryba/ranger/plugins/hbase/install', options
      commands:
        'install': ->
          options = @config.ryba.ranger.hbase_plugin
          @call 'ryba/ranger/plugins/hbase/install', options
