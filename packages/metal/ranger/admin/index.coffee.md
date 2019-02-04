
# Ranger Policy Manager

Apache Ranger offers a centralized security framework to manage fine-grained
access control over Hadoop data access components like Apache Hive and Apache HBase.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        mysql_client: module: 'masson/commons/mysql/client', local: true
        mariadb_client: module: 'masson/commons/mariadb/client', local: true, auto: true
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        ambari_repo: module: '@rybajs/metal/ambari/repo'
        # remove @rybajs/metal/solr/cloud from logs destination
        # keep only solr embedded and solr/cloud_docker
        # solr_cloud: module: '@rybajs/metal/solr/cloud'
        solr_client: module: '@rybajs/metal/solr/client', local: true
      configure:
        '@rybajs/metal/ranger/admin/configure'
      commands:
        'install': [
          # '@rybajs/metal/ranger/solr/install'
          '@rybajs/metal/ranger/solr/infra'
          '@rybajs/metal/ranger/solr/bootstrap'
          '@rybajs/metal/ranger/admin/install'
          '@rybajs/metal/ranger/admin/start'
          '@rybajs/metal/ranger/admin/setup'
        ]
        'start':
          '@rybajs/metal/ranger/admin/start'
        'status':
          '@rybajs/metal/ranger/admin/status'
        'stop':
          '@rybajs/metal/ranger/admin/stop'
        'setup':
          '@rybajs/metal/ranger/admin/setup'
