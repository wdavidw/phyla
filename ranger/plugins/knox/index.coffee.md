# Ranger Knox Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: use: true, module: 'ryba/hadoop/core', local: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        knox: module: 'ryba/knox/server', local: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
      configure:
        'ryba/ranger/plugins/knox/configure'
      plugin: ->
        options = @config.ryba.ranger.knox
        @before
          type: ['service', 'start']
          name: 'knox-server'
        , ->
          options = @config.ryba.ranger.knox
          @call 'ryba/ranger/plugins/knox/install', options
      commands:
        install: ->
          options = @config.ryba.ranger.knox
          @call 'ryba/ranger/plugins/knox/install', options
