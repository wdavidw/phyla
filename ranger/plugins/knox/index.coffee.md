# Ranger Knox Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: use: true, module: 'ryba/hadoop/core', local: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        knox: module: 'ryba/knox/server', local: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
      configure:
        'ryba/ranger/plugins/knox/configure'
      plugin: (options) ->
        @before
          type: ['service', 'start']
          name: 'knox-server'
        , ->
          delete options.original.type
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/ranger/plugins/knox/install', options.original
      commands:
        install:
          'ryba/ranger/plugins/knox/install'
