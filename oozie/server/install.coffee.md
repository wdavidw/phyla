
# Oozie Server Install

Oozie source code and examples are located in "/usr/share/doc/oozie-$version".

The current version of Oozie doesnt supported automatic failover of the Yarn
Resource Manager. RM HA (High Availability) must be configure with manual
failover and Oozie must target the active node.

    module.exports = header: 'Oozie Server Install', handler: ->
      {oozie, hadoop_group, hadoop_conf_dir, yarn, realm, db_admin, core_site, ssl_client,ssl} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]
      is_falcon_installed = @contexts('ryba/falcon/server').length isnt 0
      is_hbase_installed = @contexts('ryba/hbase/master').length isnt 0
      port = url.parse(oozie.site['oozie.base.url']).port

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## Identities

By default, the "oozie" package create the following entries:

```bash
cat /etc/passwd | grep oozie
oozie:x:493:493:Oozie User:/var/lib/oozie:/bin/bash
cat /etc/group | grep oozie
oozie:x:493:
```

      @system.group header: 'Group', oozie.group
      @system.user header: 'User', oozie.user

## IPTables

| Service | Port  | Proto | Info                      |
|---------|-------|-------|---------------------------|
| oozie   | 11443 | http  | Oozie HTTP secure server  |
| oozie   | 11001 | http  | Oozie Admin server        |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: oozie.admin_port, protocol: 'tcp', state: 'NEW', comment: "Oozie HTTP Server" }
        ]
        if: @config.iptables.action is 'start'

      @call header: 'Packages', (options) ->
        # Upgrading oozie failed, tested versions are hdp 2.1.2 -> 2.1.5 -> 2.1.7
        @system.execute
          cmd: "rm -rf /usr/lib/oozie && yum remove -y oozie oozie-client"
          if: options.retry > 0
        @service
          name: 'falcon'
          if: is_falcon_installed
        @service
          name: 'unzip' # Required by the "prepare-war" command
        @service
          name: 'zip' # Required by the "prepare-war" command
        @service
          name: 'extjs-2.2-1'
        # @call if: @contexts('ryba/falcon').length, ->
        #   @service
        #     name: 'falcon'
        #   @hdp_select
        #     name: 'falcon-client'
        @service
          name: 'falcon'
          if: @contexts('ryba/falcon').length
        @hdp_select
          name: 'falcon-client'
          if: @contexts('ryba/falcon').length
        @service
          name: 'oozie' # Also install oozie-client and bigtop-tomcat
        @hdp_select
          name: 'oozie-server'
        @hdp_select
          name: 'oozie-client'
        @call if: oozie.db.engine is 'mysql', ->
          @service
            name: 'mysql'
          @service
            name: 'mysql-connector-java'
        @service.init
          header: 'Init Script'
          source: "#{__dirname}/../resources/oozie"
          local: true
          target: '/etc/init.d/oozie'
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: oozie.pid_dir
          uid: oozie.user.name
          gid: hadoop_group.name
          perm: '0750'
        @system.execute
          cmd: "service oozie restart"
          if: -> @status -4

      @call header: 'Layout Directories', ->
        @system.mkdir
          target: oozie.data
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @system.mkdir
          target: oozie.log_dir
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @system.mkdir
          target: oozie.pid_dir
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @system.mkdir
          target: oozie.tmp_dir
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        @system.mkdir
          target: "#{oozie.conf_dir}/action-conf"
          uid: oozie.user.name
          gid: hadoop_group.name
          mode: 0o0755
        # Set permission to action conf
        @system.execute
          cmd: """
          chown -R #{oozie.user.name}:#{hadoop_group.name} #{oozie.conf_dir}/action-conf
          """
          shy: true
        # Waiting for recursivity in @system.mkdir
        # @system.execute
        #   cmd: """
        #   chown -R #{oozie.user.name}:#{hadoop_group.name} /usr/lib/oozie
        #   chown -R #{oozie.user.name}:#{hadoop_group.name} #{oozie.data}
        #   chown -R #{oozie.user.name}:#{hadoop_group.name} #{oozie.conf_dir} #/..
        #   chmod -R 755 #{oozie.conf_dir} #/..
        #   """

## Environment

Update the Oozie environment file "oozie-env.sh" located inside
"/etc/oozie/conf".

Note, environment variables are grabed by oozie and translated into java
properties inside "./bin/oozied.distro". Here's an extract:


```bash
catalina_opts="-Doozie.home.dir=${OOZIE_HOME}";
catalina_opts="${catalina_opts} -Doozie.config.dir=${OOZIE_CONFIG}";
catalina_opts="${catalina_opts} -Doozie.log.dir=${OOZIE_LOG}";
catalina_opts="${catalina_opts} -Doozie.data.dir=${OOZIE_DATA}";
catalina_opts="${catalina_opts} -Doozie.instance.id=${OOZIE_INSTANCE_ID}"
catalina_opts="${catalina_opts} -Doozie.config.file=${OOZIE_CONFIG_FILE}";
catalina_opts="${catalina_opts} -Doozie.log4j.file=${OOZIE_LOG4J_FILE}";
catalina_opts="${catalina_opts} -Doozie.log4j.reload=${OOZIE_LOG4J_RELOAD}";
catalina_opts="${catalina_opts} -Doozie.http.hostname=${OOZIE_HTTP_HOSTNAME}";
catalina_opts="${catalina_opts} -Doozie.admin.port=${OOZIE_ADMIN_PORT}";
catalina_opts="${catalina_opts} -Doozie.http.port=${OOZIE_HTTP_PORT}";
catalina_opts="${catalina_opts} -Doozie.https.port=${OOZIE_HTTPS_PORT}";
catalina_opts="${catalina_opts} -Doozie.base.url=${OOZIE_BASE_URL}";
catalina_opts="${catalina_opts} -Doozie.https.keystore.file=${OOZIE_HTTPS_KEYSTORE_FILE}";
catalina_opts="${catalina_opts} -Doozie.https.keystore.pass=${OOZIE_HTTPS_KEYSTORE_PASS}";
```

      writes = [
          match: /^export OOZIE_HTTPS_KEYSTORE_FILE=.*$/mg
          replace: "export OOZIE_HTTPS_KEYSTORE_FILE=#{oozie.keystore_file}"
          append: true
        ,
          match: /^export OOZIE_HTTPS_KEYSTORE_PASS=.*$/mg
          replace: "export OOZIE_HTTPS_KEYSTORE_PASS=#{oozie.keystore_pass}"
          append: true
        ,
          match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Djavax.net.ssl.trustStore=(.*)/m
          replace: """
          export CATALINA_OPTS="${CATALINA_OPTS} -Djavax.net.ssl.trustStore=#{oozie.truststore_file}"
          """
          append: true
        ,
          match: /^export CATALINA_OPTS="${CATALINA_OPTS} -Djavax.net.ssl.trustStorePassword=(.*)/m
          replace: """
          export CATALINA_OPTS="${CATALINA_OPTS} -Djavax.net.ssl.trustStorePassword=#{oozie.truststore_pass}"
          """
          append: true
        ]
      @file.render
        header: 'Oozie Environment'
        target: "#{oozie.conf_dir}/oozie-env.sh"
        source: "#{__dirname}/../resources/oozie-env.sh.j2"
        local: true
        context: @config
        write: writes
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0755
        backup: true

# ExtJS

Install the ExtJS Javascript library as part of enabling the Oozie Web Console.

      @system.copy
        header: 'ExtJS Library'
        source: '/usr/share/HDP-oozie/ext-2.2.zip'
        target: '/usr/hdp/current/oozie-server/libext/'

# HBase credentials

Install the HBase Libs as part of enabling the Oozie Unified Credentials with HBase.

      @system.copy
        header: 'HBase Libs'
        source: '/usr/hdp/current/hbase-client/lib/hbase-common.jar'
        target: '/usr/hdp/current/oozie-server/libserver/'

# LZO

Install the LZO compression library as part of enabling the Oozie Web Console.

      @call header: 'LZO', ->
        @call (_, callback) ->
          @service
            name: 'lzo-devel'
            relax: true
          , (err) ->
            @service.remove
              if: !!err
              name: 'lzo-devel'
            @then callback
        @service
          name: 'hadoop-lzo'
        @service
          name: 'hadoop-lzo-native'
        lzo_jar = null
        @system.execute
          cmd: 'ls /usr/hdp/current/share/lzo/*/lib/hadoop-lzo-*.jar'
        , (err, _, stdout) ->
          return if err
          lzo_jar = stdout.trim()
        @call ->
          @system.execute
            cmd: """
            # Remove any previously installed version
            rm /usr/hdp/current/oozie-server/libext/hadoop-lzo-*.jar
            # Copy lzo
            cp #{lzo_jar} /usr/hdp/current/oozie-server/libext/
            """
            unless_exists: "/usr/hdp/current/oozie-server/libext/#{path.basename lzo_jar}"

    # Note
    # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.12.4.3
    # Copy or symlink the MySQL JDBC driver JAR into the /var/lib/oozie/ directory.
      @system.link
        header: 'MySQL Driver'
        source: '/usr/share/java/mysql-connector-java.jar'
        target: '/usr/hdp/current/oozie-server/libext/mysql-connector-java.jar'

      @call header: 'Configuration', ->
        @hconfigure
          target: "#{oozie.conf_dir}/oozie-site.xml"
          source: "#{__dirname}/../resources/oozie-site.xml"
          local: true
          properties: oozie.site
          uid: oozie.user.name
          gid: oozie.group.name
          mode: 0o0755
          merge: true
          backup: true
        @file
          target: "#{oozie.conf_dir}/oozie-default.xml"
          source: "#{__dirname}/../resources/oozie-default.xml"
          local: true
          backup: true
        @hconfigure
          target: "#{oozie.conf_dir}/hadoop-conf/core-site.xml"
          # local_default: true
          properties: oozie.hadoop_config
          uid: oozie.user.name
          gid: oozie.group.name
          mode: 0o0755
          backup: true

      @call header: 'SSL Server', ->
        @java.keystore_add
          header: 'SSL'
          keystore: oozie.keystore_file
          storepass: oozie.keystore_pass
          caname: 'hadoop_root_ca'
          cacert: "#{ssl.cacert.source}"
          key: "#{ssl.key.source}"
          cert: "#{ssl.cert.source}"
          keypass: oozie.keystore_pass
          name: @config.shortname
          local: true
        @java.keystore_add
          keystore: oozie.keystore_file
          storepass: oozie.keystore_pass
          caname: 'hadoop_root_ca'
          cacert: "#{ssl.cacert.source}"
          local: ssl.cacert.local
        # fix oozie pkix build exceptionm when oozie server connects to hadoop mr
        @java.keystore_add
          keystore: oozie.truststore_file
          storepass: oozie.truststore_pass
          caname: 'hadoop_root_ca'
          cacert: "#{ssl.cacert.source}"
          local: ssl.cacert.local

      @call header: 'War', ->
        @call
          header: 'HBase'
          if: is_hbase_installed
        , ->
          files = [
            'hbase-common.jar'
            'hbase-client.jar'
            'hbase-server.jar'
            'hbase-protocol.jar'
            'hbase-hadoop2-compat.jar'
          ]
          for file in files
            @system.copy
              header: 'HBase Libs'
              source: "/usr/hdp/current/hbase-client/lib/#{file}"
              target: '/usr/hdp/current/oozie-server/libext/'
        @call
          header: 'Falcon'
          if: is_falcon_installed
        , ->
          @service
            name: 'falcon'
          @system.mkdir
            target: '/tmp/falcon-oozie-jars'
          # Note, the documentation mentions using "-d" option but it doesnt
          # seem to work. Instead, we deploy the jar where "-d" default.
          @system.execute
            # cmd: """
            # rm -rf /tmp/falcon-oozie-jars/*
            # cp  /usr/lib/falcon/oozie/ext/falcon-oozie-el-extension-*.jar \
            #   /tmp/falcon-oozie-jars
            # """, (err) ->
            cmd: """
            falconext=`ls /usr/hdp/current/falcon-client/oozie/ext/falcon-oozie-el-extension-*.jar`
            if [ -f /usr/hdp/current/oozie-server/libext/`basename $falconext` ]; then exit 3; fi
            rm -rf /tmp/falcon-oozie-jars/*
            cp  /usr/hdp/current/falcon-client/oozie/ext/falcon-oozie-el-extension-*.jar \
              /usr/hdp/current/oozie-server/libext
            """
            code_skipped: 3
          @system.execute
            cmd: """
            if [ ! -f #{oozie.pid_dir}/oozie.pid ]; then exit 3; fi
            if ! kill -0 >/dev/null 2>&1 `cat #{oozie.pid_dir}/oozie.pid`; then exit 3; fi
            su -l #{oozie.user.name} -c "/usr/hdp/current/oozie-server/bin/oozied.sh stop 20 -force"
            rm -rf cat #{oozie.pid_dir}/oozie.pid
            """
            code_skipped: 3
        # The script `ooziedb.sh` must be done as the oozie Unix user, otherwise
        # Oozie may fail to start or work properly because of incorrect file permissions.
        # There is already a "oozie.war" file inside /var/lib/oozie/oozie-server/webapps/.
        # The "prepare-war" command generate the file "/var/lib/oozie/oozie-server/webapps/oozie.war".
        # The directory being served by the web server is "prepare-war".
        # See note 20 lines above about "-d" option
        # falcon_opts = if falcon_ctxs.length then " –d /tmp/falcon-oozie-jars" else ''
        secure_opt = if oozie.secure then '-secure' else ''
        falcon_opts = ''
        @system.execute
          header: 'Prepare WAR'
          cmd: """
          chown #{oozie.user.name} /usr/hdp/current/oozie-server/oozie-server/conf/server.xml
          su -l #{oozie.user.name} -c 'cd /usr/hdp/current/oozie-server; ./bin/oozie-setup.sh prepare-war #{secure_opt} #{falcon_opts}'
          """
          code_skipped: 255 # Oozie already started, war is expected to be installed

## Kerberos

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] #.replace '_HOST', @config.host
        randkey: true
        keytab: oozie.site['oozie.service.HadoopAccessorService.keytab.file']
        uid: oozie.user.name
        gid: oozie.group.name
      @system.copy
        header: 'SPNEGO'
        source: '/etc/security/keytabs/spnego.service.keytab'
        target: "#{oozie.site['oozie.authentication.kerberos.keytab']}"
        uid: oozie.user.name
        gid: oozie.group.name
        mode: 0o0600

## SQL Database Creation

      @call header: 'SQL Database Creation', ->
        switch oozie.db.engine
          when 'mysql'
            escape = (text) -> text.replace(/[\\"]/g, "\\$&")
            version_local = db.cmd(oozie.db, "select data from OOZIE_SYS where name='oozie.version'") + "| tail -1"
            version_remote = "ls /usr/hdp/current/oozie-server/lib/oozie-client-*.jar | sed 's/.*client\\-\\(.*\\).jar/\\1/'"
            # properties =
            #   'engine': oozie.db.engine
            #   'host': oozie.db.host
            #   'admin_username': oozie.db.admin_username
            #   'admin_password': oozie.db.admin_password
            #   'username': username
            #   'password': password
            @db.user oozie.db, database: null,
              header: 'User'
              if: oozie.db.engine in ['mysql', 'postgres']
            @db.database oozie.db,
              header: 'Database'
              user: oozie.db.username
              if: oozie.db.engine in ['mysql', 'postgres']
            @db.schema oozie.db,
              header: 'Schema'
              if: oozie.db.engine is 'postgres'
              schema: oozie.db.schema or oozie.db.database
              database: oozie.db.database
              owner: oozie.db.username
            # @db.database.exists oozie.db
            # @system.execute
            #   cmd: db.cmd oozie.db, """
            #   create database #{oozie.db.database};
            #   grant all privileges on #{oozie.db.database}.* to '#{oozie.db.username}'@'localhost' identified by '#{oozie.db.password}';
            #   grant all privileges on #{oozie.db.database}.* to '#{oozie.db.username}'@'%' identified by '#{oozie.db.password}';
            #   flush privileges;
            #   """
            #   unless: -> @status -1 # true if exists
            @system.execute
               cmd: "su -l #{oozie.user.name} -c '/usr/hdp/current/oozie-server/bin/ooziedb.sh create -sqlfile /tmp/oozie.sql -run Validate DB Connection'"
               unless_exec: db.cmd oozie.db, "select data from OOZIE_SYS where name='oozie.version'"
            @system.execute
               cmd: "su -l #{oozie.user.name} -c '/usr/hdp/current/oozie-server/bin/ooziedb.sh upgrade -run'"
               unless_exec: "[[ `#{version_local}` == `#{version_remote}` ]]"
          else throw Error 'Database engine not supported'

    # module.exports.push header: 'Oozie Server Database', ->
    #   {oozie} = @config.ryba
    #   @system.execute
    #     cmd: """
    #     su -l #{oozie.user.name} -c '/usr/hdp/current/oozie-server/bin/ooziedb.sh create -sqlfile oozie.sql -run Validate DB Connection'
    #     """
    #   , (err, executed, stdout, stderr) ->
    #     err = null if err and /DB schema exists/.test stderr

# Share libs

Upload the Oozie sharelibs folder. The location of the ShareLib is specified by
the oozie.service.WorkflowAppService.system.libpath configuration property.
Inside this directory, multiple versions may cooexiste inside "lib_{timestamp}"
directories.

Oozie will automatically clean up old ShareLib "lib_{timestamp}" directories
based on the following rules:

*   After ShareLibService.temp.sharelib.retention.days days (default: 7)
*   Will always keep the latest 2

Internally, the "sharelib create" and "sharelib upgrade" commands are used to
upload the files.

Note from 4.2.0 version :
Upgrade command is deprecated, one should use create command to create new version of sharelib.
The create command executes a diff between the local Sharelib and the hdfs current sharelib,
then it uploads the diffs to the new versionned lib_ directory.
At start, server picks the sharelib from latest time-stamp directory.

The `oozie admin -shareliblist` command can be used by the final user to list
the ShareLib contents without having to go into HDFS.

      @call once: true, 'ryba/hadoop/hdfs_nn/wait'
      @call
        header: 'Share lib'
        if: @contexts('ryba/oozie/server')[0].config.host is @config.host
      , ->
        @hdfs_mkdir
          target: "/user/#{oozie.user.name}/share/lib"
          user: "#{oozie.user.name}"
          group:  "#{oozie.group.name}"
          mode: 0o0755
          krb5_user: @config.ryba.hdfs.krb5_user
        # Extract the released sharelib locally
        @call
          unless_exec:"""
          version=`ls /usr/hdp/current/oozie-server/lib | grep oozie-client | sed 's/^oozie-client-\\(.*\\)\\.jar$/\\1/g'`
          cat /usr/hdp/current/oozie-server/share/lib/sharelib.properties | grep build.version | grep $version
          """
        , ->
          @system.execute
            header: 'Remove old local version'
            cmd:"rm -Rf /usr/hdp/current/oozie-server/share"
          @tools.extract
            header: 'Extract released version'
            source: "/usr/hdp/current/oozie-server/oozie-sharelib.tar.gz"
            target: "/usr/hdp/current/oozie-server"
            unless_exec: "test -d /usr/hdp/current/oozie-server/share"
          @system.execute
             cmd:"chmod -R 0755 /usr/hdp/current/oozie-server/share/"
        # Copy additions to the local sharelib
        @call ->
          for sublib of oozie.sharelib
            for addition in oozie.sharelib[sublib]
              @system.copy
                header: "Add dependency for #{sublib}"
                source: "#{addition}"
                target: "/usr/hdp/current/oozie-server/share/lib/#{sublib}"
                mode: 0o0755
        # use bash script to copy hbase-client jar to oozie sharelib to avoid
        # too much ssh action
        #https://community.hortonworks.com/content/supportkb/49407/how-to-set-up-oozie-to-connect-to-secured-hbase-cl-1.html
        @call
          header: "HBase Sharelib"
          if: is_hbase_installed
        , ->
          @service
            name: 'hbase'
          @system.mkdir
            target: '/usr/hdp/current/oozie-server/share/lib/hbase'
          @system.execute
            header: 'Copy jars'
            code_skipped: 2
            cmd: """
            count=0
            for name in `ls -l /usr/hdp/current/hbase-client/lib/ | grep ^- | egrep '(htrace)|(hbase-)' | grep -v test | awk '{print $9}'`;
            do
              if test -f /usr/hdp/current/oozie-server/share/lib/hbase/$name;
                then
                  echo "file: $name  status: ok";
                else
                  cp /usr/hdp/current/hbase-client/lib/$name /usr/hdp/current/oozie-server/share/lib/hbase/$name
                  count=$((count+1))
                  echo "file: $name  status: copied";
              fi;
              done;
            if [ $count -eq 0 ] ; then exit 2 ; else exit 0; fi
            """
        # Deploy a versionned sharelib
        @system.execute
          if: -> @status -1 or @status -2 or @status -3 or @status -4
          header: 'Deploy to HDFS'
          cmd: mkcmd.hdfs @, """
          su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozie-setup.sh sharelib create -fs #{core_site['fs.defaultFS']} /usr/hdp/current/oozie-server/share"
          hdfs dfs -chmod -R 755 /user/#{oozie.user.name}
          """
          trap: true

## Hive Site

      @hconfigure
        header: 'Hive Site'
        if: is_falcon_installed
        target: "#{oozie.conf_dir}/action-conf/hive.xml"
        properties: 'hive.metastore.execute.setugi': 'true'
        merge: true

## Log4J properties

      # Instructions mention updating convertion pattern to the same value as
      # default, skip for now
      #TODO: Declare all properties during configure and use write_properties
      @file
        header: 'Log4J properties'
        target: "#{oozie.conf_dir}/oozie-log4j.properties"
        source: "#{__dirname}/../resources/oozie-log4j.properties"
        local: true
        backup: true
        write: for k, v of oozie.log4j
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true

## Dependencies

    url = require 'url'
    path = require 'path'
    mkcmd = require '../../lib/mkcmd'
    db = require 'nikita/lib/misc/db'
    quote = require 'regexp-quote'
