
# Ranger Admin Install

    module.exports =  header: 'Ranger Admin Install', handler: ({options}) ->

## Register

      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'
      @registry.register 'hconfigure', '@rybajs/metal/lib/hconfigure'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Package

Install the Ranger Policy Manager package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

      @call header: 'Packages', ->
        @service.install
          name: 'ranger-admin'
        @hdp_select
          name: 'ranger-admin'

## Layout

      @system.mkdir
        target: '/var/run/ranger'
        uid: options.user.name
        gid: options.user.name
        mode: 0o750

## IPTables

| Service              | Port  | Proto       | Parameter          |
|----------------------|-------|-------------|--------------------|
| Ranger policymanager | 6080  | http        | port               |
| Ranger policymanager | 6182  | https       | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'Ranger Admin IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.site['ranger.service.http.port'], protocol: 'tcp', state: 'NEW', comment: "Ranger Admin HTTP WEBUI" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.site['ranger.service.https.port'], protocol: 'tcp', state: 'NEW', comment: "Ranger Admin HTTPS WEBUI" }
        ]

## Ranger Admin Driver

      @system.link
        header: 'DB Driver'
        source: '/usr/share/java/mysql-connector-java.jar'
        target: options.install['SQL_CONNECTOR_JAR']

## Ranger Databases

      @call header: 'DB Setup', ->
        switch options.db.engine
          when 'mariadb', 'mysql'
            # mysql_exec = "mysql -u#{options.db.admin_username} -p#{options.db.admin_password} -h#{options.db.host} -P#{options.db.port} "
            @system.execute
              cmd: db.cmd options.db, """
              SET GLOBAL log_bin_trust_function_creators = 1;
              create database  #{options.install['db_name']};
              grant all privileges on #{options.install['db_name']}.* to #{options.install['db_user']}@'localhost' identified by '#{options.install['db_password']}';
              grant all privileges on #{options.install['db_name']}.* to #{options.install['db_user']}@'%' identified by '#{options.install['db_password']}';
              flush privileges;
              """
              unless_exec: db.cmd options.db, "use #{options.install['db_name']}"
            @system.execute
              cmd: db.cmd options.db, """
              create database  #{options.install['audit_db_name']};
              grant all privileges on #{options.install['audit_db_name']}.* to #{options.install['audit_db_user']}@'localhost' identified by '#{options.install['audit_db_password']}';
              grant all privileges on #{options.install['audit_db_name']}.* to #{options.install['audit_db_user']}@'%' identified by '#{options.install['audit_db_password']}';
              flush privileges;
              """
              unless_exec: db.cmd options.db, "use #{options.install['audit_db_name']}"

## Install Scripts

Update the file "install.properties" with the properties defined by the
"install" option.

      @file
        header: 'Setup Scripts'
        source: "#{__dirname}/../resources/admin-install.properties"
        target: '/usr/hdp/current/ranger-admin/install.properties'
        local: true
        eof: true
        backup: true
        write: for k, v of options.install
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true

## Setup Ranger Admin 

Follow [the instructions][instruction-24-25] for upgrade.
Sometime you can fall on this error on mysql databse.

This function has none of DETERMINISTIC, NO SQL, or READS SQL DATA in its declaration 
and binary logging is enabled.

To pass the setup script you have to set log_bin_trust_function_creators variable to 1
to allow user to create none-determisitic functions.

      @system.execute
        header: 'Setup Execution'
        cmd: """
        cd /usr/hdp/current/ranger-admin/
        ./setup.sh
        """
      @system.execute
        header: 'Fix Setup Execution'
        cmd: "chown -R #{options.user.name}:#{options.user.name} #{options.conf_dir}"
      @hconfigure
        header: 'Core site'
        target: '/etc/ranger/admin/conf/core-site.xml'
        properties: options.core_site
        backup: true
      # the setup scripts already render an init.d script but it does not respect 
      # the convention exit code 3 when service is stopped on the status code
      @service.init
        target: '/etc/init.d/ranger-admin'
        source: "#{__dirname}/../resources/ranger-admin.j2"
        local: true
        mode: 0o0755
        context: options
      @system.tmpfs
        if_os: name: ['redhat','centos'], version: '7'
        mount: '/var/run/ranger'
        uid: options.user.name
        gid: options.user.name
      @system.execute
        header: 'Credential db alias'
        cmd: """
        cd /usr/hdp/current/ranger-admin/
        java -cp "cred/lib/*" org.apache.ranger.credentialapi.buildks create '#{options.site['ranger.jpa.jdbc.credential.alias']}' \ 
        -value '#{options.install['db_password']}'  -provider jceks://file#{options.site['ranger.credential.provider.path']}
        """
        unless_exec: """
          cd /usr/hdp/current/ranger-admin/
          java -cp "cred/lib/*" org.apache.ranger.credentialapi.buildks list \ 
          -provider jceks://file#{options.site['ranger.credential.provider.path']} | grep '#{options.site['ranger.jpa.jdbc.credential.alias']}'
        """
      @system.execute
        header: 'Credential ssl keystore'
        cmd: """
        cd /usr/hdp/current/ranger-admin/
        java -cp "cred/lib/*" org.apache.ranger.credentialapi.buildks create '#{options.site['ranger.service.https.attrib.keystore.credential.alias']}' \ 
        -value '#{options.ssl.keystore.password}'  -provider jceks://file#{options.site['ranger.credential.provider.path']}
        """
        unless_exec: """
          cd /usr/hdp/current/ranger-admin/
          java -cp "cred/lib/*" org.apache.ranger.credentialapi.buildks list \ 
          -provider jceks://file#{options.site['ranger.credential.provider.path']} | grep '#{options.site['ranger.service.https.attrib.keystore.credential.alias']}'
        """
      @system.execute
        header: 'Credential ssl truststore'
        cmd: """
        cd /usr/hdp/current/ranger-admin/
        java -cp "cred/lib/*" org.apache.ranger.credentialapi.buildks create '#{options.site['ranger.truststore.alias']}' \ 
        -value '#{options.ssl.truststore.password}'  -provider jceks://file#{options.site['ranger.credential.provider.path']}
        """
        unless_exec: """
          cd /usr/hdp/current/ranger-admin/
          java -cp "cred/lib/*" org.apache.ranger.credentialapi.buildks list \ 
          -provider jceks://file#{options.site['ranger.credential.provider.path']} | grep '#{options.site['ranger.truststore.alias']}'
        """
      @service
        name: 'ranger-admin'
        startup: true

## SSL

      @call
        header: 'Configure SSL'
        if: (options.site['ranger.service.https.attrib.ssl.enabled'] is 'true')
      , ->
        @java.keystore_add
          header: 'SSL'
          keystore: options.site['ranger.service.https.attrib.keystore.file']
          storepass: options.ssl.keystore.password
          key: "#{options.ssl.key.source}"
          cert: "#{options.ssl.cert.source}"
          keypass: options.ssl.keystore.password
          name: options.site['ranger.service.https.attrib.keystore.keyalias']
          local: "#{options.ssl.cert.local}"
        @java.keystore_add
          keystore: options.site['ranger.service.https.attrib.keystore.file']
          storepass: options.ssl.keystore.password
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: "#{options.ssl.cacert.local}"
        @java.keystore_add
          # shouldnt be "/etc/pki/java/cacerts"?
          keystore: '/usr/java/latest/jre/lib/security/cacerts'
          storepass: 'changeit'
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: "#{options.ssl.cacert.local}"
        @java.keystore_add
          keystore: options.site['ranger.truststore.file']
          storepass: options.ssl.truststore.password
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: "#{options.ssl.cacert.local}"
        @hconfigure
          header: 'Admin site'
          target: '/etc/ranger/admin/conf/ranger-admin-site.xml'
          properties: options.site
          merge: true
          backup: true

## Ranger Admin Principal

      @krb5.addprinc options.krb5.admin,
        if: options.plugins.principal
        header: 'Ranger Repositories principal'
        principal: options.plugins.principal
        randkey: true
        password: options.plugins.password
      @krb5.addprinc options.krb5.admin,
        header: 'Ranger Web UI'
        principal: options.install['admin_principal']
        randkey: true
        keytab: options.install['admin_keytab']
        uid: options.user.name
        gid: options.user.name
        mode: 0o600
      @krb5.addprinc options.krb5.admin,
        header: 'Ranger Web UI'
        principal: options.install['lookup_principal']
        randkey: true
        keytab: options.install['lookup_keytab']
        uid: options.user.name
        gid: options.user.name
        mode: 0o600

## Java env
This part of the setup is not documented. Deduce from launch scripts.

      @call header: 'Ranger Admin Env', ->
        writes = [
          match: RegExp "JAVA_OPTS=.*", 'm'
          replace: "JAVA_OPTS=\"${JAVA_OPTS} -Xmx#{options.heap_size} -Xms#{options.heap_size} \""
          append: true
        ,

          match: RegExp "export CLASSPATH=.*", 'mg'
          replace: "export CLASSPATH=\"$CLASSPATH:/etc/hadoop/conf:/etc/hbase/conf:/etc/hive/conf\" Ryba Fix conf resources"
          append:true

        ]
        for k,v of options.opts
          writes.push
            match: RegExp "^JAVA_OPTS=.*#{k}", 'm'
            replace: "JAVA_OPTS=\"${JAVA_OPTS} -D#{k}=#{v}\" # RYBA, DONT OVERWRITE"
            append: true
        @file
          target: '/etc/ranger/admin/conf/ranger-admin-env-1.sh'
          write: writes
          backup: true
          mode: 0o750
          uid: options.user.name
          gid: options.group.name

## Log4j

      @file.properties
        target: '/etc/ranger/admin/conf/log4j.properties'
        header: 'ranger Log4properties'
        content: options.log4j

      @service.restart
        name: 'ranger-admin'
        if: -> @status()

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'
    db = require '@nikitajs/core/lib/misc/db'

[instruction-24-25]:http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_command-line-upgrade/content/upgrade-ranger_24.html
