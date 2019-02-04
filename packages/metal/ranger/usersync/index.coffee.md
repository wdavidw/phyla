
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
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client'
        hadoop_core: implicit: true, module: '@rybajs/metal/hadoop/core'
        ranger_admin: module: '@rybajs/metal/ranger/admin'
      configure: '@rybajs/metal/ranger/usersync/configure'
      commands:
        'install': [
          '@rybajs/metal/ranger/usersync/install'
          '@rybajs/metal/ranger/usersync/start'
        ]
        'start':
          '@rybajs/metal/ranger/usersync/start'
        'stop':
          '@rybajs/metal/ranger/usersync/stop'
