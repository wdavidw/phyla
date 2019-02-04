
# Ranger HDFS Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn', required: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn', local: true, required: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true, required: true
      configure:
        '@rybajs/metal/ranger/plugins/hdfs/configure'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'hadoop-hdfs-namenode'
        , ->
          @call '@rybajs/metal/ranger/plugins/hdfs/install', options
      commands:
        'install':
          '@rybajs/metal/ranger/plugins/hdfs/install'
