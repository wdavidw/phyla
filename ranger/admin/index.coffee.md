
# Ranger Policy Manager

Apache Ranger offers a centralized security framework to manage fine-grained
access control over Hadoop data access components like Apache Hive and Apache HBase.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        mysql_client: module: 'masson/commons/mysql/client', local: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
        solr_cloud_docker: module: 'ryba/solr/cloud_docker'
        solr_cloud: module: 'ryba/solr/cloud'
        solr_standalone: module: 'ryba/solr/standalone'
      configure:
        'ryba/ranger/admin/configure'
      commands:
        'install': ->
          options = @config.ryba.ranger.admin
          # @call 'ryba/ranger/admin/solr_bootstrap', options
          @call 'ryba/ranger/solr/install', options
          @call 'ryba/ranger/admin/install', options
          @call 'ryba/ranger/admin/start', options
          @call 'ryba/ranger/admin/setup', options
        'start': 'ryba/ranger/admin/start'
        'status': 'ryba/ranger/admin/status'
        'stop': ->
          options = @config.ryba.ranger.admin
          @call 'ryba/ranger/admin/stop', options
