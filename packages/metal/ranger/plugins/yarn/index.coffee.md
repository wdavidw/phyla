# Ranger HDFS Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm', local: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm'
        yarn_rm_local: module: '@rybajs/metal/hadoop/yarn_rm', local: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true, required: true
        ranger_hdfs: module: '@rybajs/metal/ranger/plugins/hdfs', required: true
      configure:
        '@rybajs/metal/ranger/plugins/yarn/configure'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'hadoop-yarn-resourcemanager'
        , ->
          @call '@rybajs/metal/ranger/plugins/yarn/install', options
        @before
          action: ['service', 'start']
          name: 'hadoop-yarn-nodemanager'
        , ->
          @call '@rybajs/metal/ranger/plugins/yarn/install', options
      commands:
        'install':
          '@rybajs/metal/ranger/plugins/yarn/install'
