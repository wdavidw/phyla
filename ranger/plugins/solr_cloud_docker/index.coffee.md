# Ranger Solr Plugin
Install Solr Plugin by default on solr_cloud_docker host.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        solr_cloud_docker: module: 'ryba/solr/cloud_docker', local: true, required: true
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs', required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true, required: true
        ranger_solr_cloud_docker: module: 'ryba/ranger/plugins/solr_cloud_docker'
      configure:
        'ryba/ranger/plugins/solr_cloud_docker/configure'
      plugin: (options) ->
        @before
          type: ['docker', 'compose','up']
        , ->
          delete options.original.type
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/ranger/plugins/solr_cloud_docker/install', options.original
