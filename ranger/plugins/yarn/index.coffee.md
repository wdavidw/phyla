# Ranger HDFS Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        yarn_nm: module: 'ryba/hadoop/yarn_nm', local: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_rm_local: module: 'ryba/hadoop/yarn_rm', local: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs', required: true
      configure:
        'ryba/ranger/plugins/yarn/configure'
      plugin: (options) ->
        @before
          action: ['service', 'start']
          name: 'hadoop-yarn-resourcemanager'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/ranger/plugins/yarn/install', options.original
        @before
          action: ['service', 'start']
          name: 'hadoop-yarn-nodemanager'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/ranger/plugins/yarn/install', options.original
      commands:
        'install':
          'ryba/ranger/plugins/yarn/install'
