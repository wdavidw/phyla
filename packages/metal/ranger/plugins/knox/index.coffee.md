# Ranger Knox Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: use: true, module: '@rybajs/metal/hadoop/core', local: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        knox: module: '@rybajs/metal/knox/server', local: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true, required: true
      configure:
        '@rybajs/metal/ranger/plugins/knox/configure'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'knox-server'
        , ->
          @call '@rybajs/metal/ranger/plugins/knox/install', options
      commands:
        install:
          '@rybajs/metal/ranger/plugins/knox/install'
