# Ranger HBase Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        hbase_master: module: 'ryba/hbase/master'#, local: true
        hbase_regionserver: module: 'ryba/hbase/regionserver', local: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs', required: true
      configure:
        'ryba/ranger/plugins/hbase/configure'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'hbase-master'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/ranger/plugins/hbase/install', options.original
        @before
          action: ['service', 'start']
          name: 'hbase-regionserver'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/ranger/plugins/hbase/install', options.original
      commands:
        install:
          'ryba/ranger/plugins/hbase/install'
