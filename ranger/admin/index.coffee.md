
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
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        # remove ryba/solr/cloud from logs destination
        # keep only solr embedded and solr/cloud_docker
        # solr_cloud: module: 'ryba/solr/cloud'
        solr_client: module: 'ryba/solr/client', local: true
      configure:
        'ryba/ranger/admin/configure'
      commands:
        'install': [
          # 'ryba/ranger/solr/install'
          'ryba/ranger/solr/bootstrap'
          'ryba/ranger/admin/install'
          'ryba/ranger/admin/start'
          'ryba/ranger/admin/setup'
        ]
        'start':
          'ryba/ranger/admin/start'
        'status':
          'ryba/ranger/admin/status'
        'stop':
          'ryba/ranger/admin/stop'
        'setup':
          'ryba/ranger/admin/setup'
