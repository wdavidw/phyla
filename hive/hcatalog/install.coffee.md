
# Hive HCatalog Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

    module.exports =  header: 'Hive HCatalog Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'hdfs_upload', 'ryba/lib/hdfs_upload'

## IPTables

| Service        | Port  | Proto | Parameter            |
|----------------|-------|-------|----------------------|
| Hive Metastore | 9083  | http  | hive.metastore.uris  |
| Hive Web UI    | 9999  | http  | hive.hwi.listen.port |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

Note, since Hive 1.3, the port is defined by "'hive.metastore.port'"

      rules =  [
        { chain: 'INPUT', jump: 'ACCEPT', dport: options.hive_site['hive.metastore.port'], protocol: 'tcp', state: 'NEW', comment: "Hive Metastore" }
        { chain: 'INPUT', jump: 'ACCEPT', dport: options.hive_site['hive.hwi.listen.port'], protocol: 'tcp', state: 'NEW', comment: "Hive Web UI" }
      ]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: parseInt(options.env["JMXPORT"],10), protocol: 'tcp', state: 'NEW', comment: "Metastore JMX" } if options.env["JMXPORT"]?
      @tools.iptables
        header: 'IPTables'
        rules: rules
        if: options.iptables

## Identitites

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep hive
hive:x:493:493:Hive:/var/lib/hive:/sbin/nologin
cat /etc/group | grep hive
hive:x:493:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Ulimit

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

## Startup

Install the "hive-hcatalog-server" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

Note, the server is not activated on startup but they endup as zombies if HDFS
isnt yet started.

      @call header: 'Service', ->
        @service
          name: 'hive'
        @hdp_select
          name: 'hive-webhcat'
        @service
          name: 'hive-hcatalog-server'
        @hdp_select
          name: 'hive-metastore'
        @service.init
          header: 'Init Script'
          source: "#{__dirname}/../resources/hive-hcatalog-server.j2"
          local: true
          target: '/etc/init.d/hive-hcatalog-server'
          context: options: options
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          perm: '0750'

## Configuration

      @hconfigure
        header: 'Hive Site'
        target: "#{options.conf_dir}/hive-site.xml"
        source: "#{__dirname}/../../resources/hive/hive-site.xml"
        local: true
        properties: options.hive_site
        merge: true
        backup: true
      @file.properties
        header: 'Hive server Log4j properties'
        target: "#{options.conf_dir}/hive-log4j.properties"
        content: options.log4j.properties
        backup: true
      @file.render
        header: 'Exec Log4j'
        target: "#{options.conf_dir}/hive-exec-log4j.properties"
        source: "#{__dirname}/../resources/hive-exec-log4j.properties"
        local: true
        context: options: options
      @system.execute
        header: 'Directory Permission'
        cmd: """
        chown -R #{options.user.name}:#{options.group.name} #{options.conf_dir}/
        chmod -R 755 #{options.conf_dir}
        """
        shy: true # TODO: idempotence by detecting ownerships and permissions

## Env

Enrich the "hive-env.sh" file with the value of the options
"opts" and "heapsize". Internally, the
environmental variables "HADOOP_CLIENT_OPTS" and "HADOOP_HEAPSIZE" are enriched
and they only apply to the Hive HCatalog server.

Using this functionnality, a user may for example raise the heap size of Hive
HCatalog to 4Gb by either setting a "opts" value equal to "-Xmx4096m" or the 
by setting a "heapsize" value equal to "4096".

Note, the startup script found in "hive-hcatalog/bin/hcat_server.sh" references
the Hive Metastore service and execute "./bin/hive --service metastore"

      @file.render
        header: 'Hive Env'
        source: "#{__dirname}/../resources/hive-env.sh.j2"
        target: "#{options.conf_dir}/hive-env.sh"
        local: true
        context: options: options
        eof: true
        mode: 0o750
        backup: true
        write: [
          match: RegExp "^export HIVE_CONF_DIR=.*$", 'mg'
          replace: "export HIVE_CONF_DIR=#{options.conf_dir}"
        ]
      @call
        header: 'Upload Libs'
        if: -> options.libs.length
      , ->
        @file.download (
          source: lib
          target: "/usr/hdp/current/hive-metastore/lib/#{path.basename lib}"
        ) for lib in options.libs
      @system.link
        header: 'Link MySQL Driver'
        if: options.db.engine in ['mariadb', 'mysql']
        source: '/usr/share/java/mysql-connector-java.jar'
        target: '/usr/hdp/current/hive-metastore/lib/mysql-connector-java.jar'
      @system.link
        header: 'Link PostgreSQL Driver'
        if: options.db.engine is 'postgresql'
        source: '/usr/share/java/postgresql-jdbc.jar'
        target: '/usr/hdp/current/hive-metastore/lib/postgresql-jdbc.jar'

## Metastore DB

      @call header: 'Metastore DB', ->
        target_version = 'ls /usr/hdp/current/hive-metastore/lib | grep hive-common- | sed \'s/^hive-common-\\([0-9]\\+.[0-9]\\+.[0-9]\\+\\).*\\.jar$/\\1/g\''
        current_version =
          switch options.db.engine
            when 'mariadb', 'mysql' then db.cmd options.db, admin_username: null, 'select SCHEMA_VERSION from VERSION'
            when 'postgresql' then db.cmd options.db, admin_username: null, 'select \\"SCHEMA_VERSION\\" from \\"VERSION\\"'
        engine = options.db.engine
        engine = 'mysql' if engine is 'mariadb'
        engine = 'postgresql' if engine is 'postgresql'
        # migration: wdavidw 170907, used to be hadoop conf_dir
        @system.execute
          header: 'Init Schema'
          unless_exec: """
          hive \
            --config #{options.conf_dir} \
            --service schemaTool \
            -dbType #{engine} \
            -info
          """
          cmd: """
          hive \
            --config #{options.conf_dir} \
            --service schemaTool \
            -dbType #{engine} \
            -initSchema
          """
        @system.execute
          header: 'Read Versions'
          cmd: """
          engine="#{engine}"
          cd /usr/hdp/current/hive-metastore/scripts/metastore/upgrade/${engine} # Required for sql sources
          target_version=`#{target_version}`
          current_version=`#{current_version}`
          if [ "$target_version" == "$current_version" ] ; then exit 0; else exit 1; fi
          """
          code_skipped: 1
        # migration: wdavidw 170907, used to be hadoop conf_dir
        @system.execute
          header: 'Upgrade'
          if: -> !@status(-1) and !@status(-2)
          cmd: """
          engine="#{engine}"
          current_version=`#{current_version}`
          cd /usr/hdp/current/hive-metastore/scripts/metastore/upgrade/${engine} # Required for sql sources
          hive \
            --config #{options.conf_dir} \
            --service schemaTool \
            -dbType $engine \
            -upgradeSchemaFrom $current_version
          """
        # need to create manually some missing table in HDP >= 2.5 (HDP official KB)
        # HDP has backported patchs from hive 2.0 to hdp 2.5-1.2.1 version
        # but scripts area not up-to-date
        # did not test the need on other type of engine
        @system.execute
          header: "Upgrade"
          if: options.db.engine in ['mariadb', 'mysql']
          cmd: "#{db.cmd options.db, admin_username: null} < /usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql/026-HIVE-12818.mysql.sql"
          unless_exec:  db.cmd options.db, admin_username: null, 'SHOW CREATE TABLE COMPLETED_COMPACTIONS'
        @system.execute
          header: 'WRITE_SET'
          if: options.db.engine in ['mariadb', 'mysql']
          cmd: db.cmd options.db, admin_username: null, cmd: """
            CREATE TABLE WRITE_SET (
              WS_DATABASE varchar(128) NOT NULL,
              WS_TABLE varchar(128) NOT NULL,
              WS_PARTITION varchar(767),
              WS_TXNID bigint NOT NULL,
              WS_COMMIT_ID bigint NOT NULL,
              WS_OPERATION_TYPE char(1) NOT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
            ALTER TABLE COMPACTION_QUEUE ADD CQ_TBLPROPERTIES varchar(2048);
            ALTER TABLE COMPLETED_COMPACTIONS ADD CC_TBLPROPERTIES varchar(2048);
            ALTER TABLE TXN_COMPONENTS ADD TC_OPERATION_TYPE char(1) NOT NULL;
           """
          unless_exec:  db.cmd options.db, admin_username: null, 'SHOW CREATE TABLE WRITE_SET'

## Kerberos

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.hive_site['hive.metastore.kerberos.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.hive_site['hive.metastore.kerberos.keytab.file']
        uid: options.user.name
        gid: options.group.name
        mode: 0o0600

## Layout

Create the directories to store the logs and pid information. The options
"log\_dir" and "pid\_dir" may be modified.

      @call header: 'Layout', ->
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
          parent: true
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          parent: true

## HDFS Layout

[Coudera](http://www.cloudera.com/documentation/cdh/5-1-x/CDH5-Installation-Guide/cdh5ig_filesystem_perm.html)
recommends setting permissions on the Hive warehouse directory to 1777, making it 
accessible to all users, with the sticky bit set. This allows users to create 
and access their tables, but prevents them from deleting tables they don't 
own.

      @call header: 'HDFS Layout', ->
        # cmd = mkcmd.hdfs @, "hdfs dfs -config #{options.hdfs_conf_dir} -test -d /user && hdfs dfs -test -d /apps && hdfs dfs -test -d /tmp"
        # @wait.execute
        #   cmd: cmd
        #   code_skipped: 1
        # migration: wdavidw 170907, commented since the if condition disabled it
        # @system.execute
        #   cmd: mkcmd.hdfs @, """
        #   if hdfs dfs -ls /user/#{hive_user} &>/dev/null; then exit 1; fi
        #   hdfs dfs -mkdir /user/#{hive_user}
        #   hdfs dfs -chown #{hive_user}:#{hdfs.user.name} /user/#{hive_user}
        #   """
        #   code_skipped: 1
        #   if: false # Disabled
        # migration: wdavidw 170907, get path from config and change permissions
        @hdfs_mkdir
          header: 'Warehouse'
          target: options.hive_site['hive.metastore.warehouse.dir']
          user: options.user.name
          group: options.group.name
          mode: 0o1777
          parent:
            mode: 0o0711
          conf_dir: options.hdfs_conf_dir
          krb5_user: options.hdfs_krb5_user
        # @system.execute
        #   cmd: mkcmd.hdfs @, """
        #   if hdfs dfs -ls /apps/#{hive_user}/warehouse &>/dev/null; then exit 3; fi
        #   hdfs dfs -mkdir /apps/#{hive_user}
        #   hdfs dfs -mkdir /apps/#{hive_user}/warehouse
        #   hdfs dfs -chown -R #{hive_user}:#{hdfs.user.name} /apps/#{hive_user}
        #   hdfs dfs -chmod 755 /apps/#{hive_user}
        #   """
        #   code_skipped: 3
        # @system.execute
        #   cmd: mkcmd.hdfs @, "hdfs dfs -chmod -R #{hive.warehouse_mode or '1777'} /apps/#{hive_user}/warehouse"
       # migration: wdavidw 170907, get path from config and change group ownerships
        @hdfs_mkdir
          header: 'Warehouse Dir'
          target: options.hive_site['hive.metastore.warehouse.dir']
          user: options.user.name
          group: options.group.name
          mode: options.warehouse_mode
          parent:
            mode: 0o0711
          conf_dir: options.hdfs_conf_dir
          krb5_user: options.hdfs_krb5_user
        @hdfs_mkdir
          header: 'Scratch Dir'
          target: options.hive_site['hive.exec.scratchdir']
          user: options.user.name
          group: options.group.name
          mode: 0o1777
          parent:
            mode: 0o0711
          conf_dir: options.hdfs_conf_dir
          krb5_user: options.hdfs_krb5_user
        # @system.execute
        #   cmd: mkcmd.hdfs @, """
        #   if hdfs dfs -ls /tmp/scratch &> /dev/null; then exit 1; fi
        #   hdfs dfs -mkdir /tmp 2>/dev/null
        #   hdfs dfs -mkdir /tmp/scratch
        #   hdfs dfs -chown #{hive_user}:#{hdfs.user.name} /tmp/scratch
        #   hdfs dfs -chmod -R 1777 /tmp/scratch
        #   """
        #   code_skipped: 1

## Tez

      @service
        header: 'Tez Package'
        name: 'tez'
        if: -> options.tez_enabled
      @system.execute
        header: 'Tez Layout'
        if: -> options.tez_enabled
        cmd: 'ls /usr/hdp/current/hive-metastore/lib | grep hive-exec- | sed \'s/^hive-exec-\\(.*\\)\\.jar$/\\1/g\''
        shy: true
      , (err, status, stdout) ->
        version = stdout.trim() unless err
        @hdfs_upload
          source: "/usr/hdp/current/hive-metastore/lib/hive-exec-#{version}.jar"
          target: "/apps/hive/install/hive-exec-#{version}.jar"
          clean: "/apps/hive/install/hive-exec-*.jar"
          lock: "/tmp/hive-exec-#{version}.jar"

## SSL

      # migration: wdavidw 170906, not sure if this is required, can't find it 
      # anywhere in the doc, let's try without it first
      # @java.keystore_add
      #   header: 'Client SSL'
      #   keystore: options.truststore_location
      #   storepass: options.truststore_password
      #   caname: "hive_root_ca"
      #   cacert: ssl.cacert
      #   local: true

# Module Dependencies

    path = require 'path'
    db = require 'nikita/lib/misc/db'
    mkcmd = require '../../lib/mkcmd'
