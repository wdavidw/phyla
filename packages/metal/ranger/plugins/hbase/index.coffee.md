# Ranger HBase Plugin

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        hbase_master: module: '@rybajs/metal/hbase/master'#, local: true
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver', local: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true, required: true
        ranger_hdfs: module: '@rybajs/metal/ranger/plugins/hdfs', required: true
      configure:
        '@rybajs/metal/ranger/plugins/hbase/configure'
      plugin: ({options}) ->
        @before
          action: ['service', 'start']
          name: 'hbase-master'
        , ->
          @call '@rybajs/metal/ranger/plugins/hbase/install', options
        @before
          action: ['service', 'start']
          name: 'hbase-regionserver'
        , ->
          @call '@rybajs/metal/ranger/plugins/hbase/install', options
      commands:
        install:
          '@rybajs/metal/ranger/plugins/hbase/install'
