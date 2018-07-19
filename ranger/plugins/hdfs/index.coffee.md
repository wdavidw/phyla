
# Ranger HDFS Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn', required: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', local: true, required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
      configure:
        'ryba/ranger/plugins/hdfs/configure'
      plugin: (options) ->
        @before
          action: ['service', 'start']
          name: 'hadoop-hdfs-namenode'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/ranger/plugins/hdfs/install', options.original
      commands:
        'install':
          'ryba/ranger/plugins/hdfs/install'
