# Ranger HDFS Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm', local: true, required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
      configure:
        'ryba/ranger/plugins/yarn/configure'
      commands:
        'install': ->
          options = @config.ryba.ranger.yarn_plugin
          @call 'ryba/ranger/plugins/yarn/install', options
