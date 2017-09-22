# Ranger HBase Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hbase_master: module: 'ryba/hbase/master'#, local: true
        hbase_regionserver: module: 'ryba/hbase/regionserver', local: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs', required: true
      configure:
        'ryba/ranger/plugins/hbase/configure'
      plugin: ->
        options = @config.ryba.ranger.hbase
        @before
          type: ['service', 'start']
          name: 'hbase-master'
        , ->
          @call 'ryba/ranger/plugins/hbase/install', options
        @before
          type: ['service', 'start']
          name: 'hbase-regionserver'
        , ->
          @call 'ryba/ranger/plugins/hbase/install', options
      commands:
        'install': ->
          options = @config.ryba.ranger.hbase_plugin
          @call 'ryba/ranger/plugins/hbase/install', options
