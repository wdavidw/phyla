
# Ranger Policy Manager

Apache Ranger offers a centralized security framework to manage fine-grained
access control over Hadoop data access components like Apache Hive and Apache HBase.
Ranger User sync is a process separated from ranger policy manager, which is in charg of
importing user/groups from different sources (LDAP, AD, UNIX).

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        openldap_server: module: 'masson/core/openldap_server'
        java: module: 'masson/commons/java', local: true
        db_admin: module: 'ryba/commons/db_admin', local: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client'
        hadoop_core: implicit: true, module: 'ryba/hadoop/core'
        ranger_admin: module: 'ryba/ranger/admin'
      configure: 'ryba/ranger/usersync/configure'
      commands:
        'install': [
          'ryba/ranger/usersync/install'
          'ryba/ranger/usersync/start'
        ]
        'start':
          'ryba/ranger/usersync/start'
        'stop':
          'ryba/ranger/usersync/stop'
