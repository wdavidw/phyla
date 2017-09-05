# Ranger HDFS Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm', local: true, required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
      configure:
        'ryba/ranger/plugins/yarn/configure'
      plugin: ->
        options = @config.ryba.ranger.yarn
        @before
          type: ['service', 'start']
          name: 'hadoop-yarn-resourcemanager'
        , ->
          @call 'ryba/ranger/plugins/yarn/install', options
      commands:
        'install': ->
          options = @config.ryba.ranger.yarn
          @call 'ryba/ranger/plugins/yarn/install', options
