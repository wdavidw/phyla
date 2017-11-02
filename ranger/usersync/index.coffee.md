
# Ranger Policy Manager

Apache Ranger offers a centralized security framework to manage fine-grained
access control over Hadoop data access components like Apache Hive and Apache HBase.
Ranger User sync is a process separated from ranger policy manager, which is in charg of
importing user/groups from different sources (LDAP, AD, UNIX).

    module.exports =
      use:
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
        'install': ->
          options = @config.ryba.ranger.usersync
          @call 'ryba/ranger/usersync/install', options
          @call 'ryba/ranger/usersync/start', options
        'start': ->
          options = @config.ryba.ranger.usersync
          @call 'ryba/ranger/usersync/start', options
        'stop': ->
          options = @config.ryba.ranger.usersync
          @call 'ryba/ranger/usersync/stop', options
s
