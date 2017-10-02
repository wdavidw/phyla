
# Solr Install

    module.exports = header: 'Solr Cloud Install', handler: (options) ->
      tmp_archive_location = "/var/tmp/ryba/solr.tar.gz"
      protocol = if options.ssl.enabled then 'https' else 'http'

## Dependencies
Wait for Kerberos, ZooKeeper

      @call once: true, 'masson/core/krb5_client/wait', options.wait_krb5_client
      @call once: true, 'ryba/zookeeper/server/wait', options.wait_zookeeper_server
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## IPTables

| Service      | Port  | Proto       | Parameter          |
|--------------|-------|-------------|--------------------|
| Solr Server  | 8983  | http        | port               |
| Solr Server  | 9983  | https       | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPtable'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.port, protocol: 'tcp', state: 'NEW', comment: "Solr Server #{protocol}" }
        ]

## Layout

      @system.mkdir
        target: options.user.home
        uid: options.user.name
        gid: options.group.name
      @system.mkdir
        directory: options.conf_dir
        uid: options.user.name
        gid: options.group.name

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Packages
Ryba support installing solr from apache official release or HDP Search repos.

      @call header: 'Packages', ->
        @call
          if:  options.source is 'HDP'
        , ->
          @service
            name: 'lucidworks-hdpsearch'
          @system.chown
            if: options.source is 'HDP'
            target: '/opt/lucidworks-hdpsearch'
            uid: options.user.name
            gid: options.group.name
        @call
          if: options.source isnt 'HDP'
        , ->
          @file.download
            source: options.source
            target: tmp_archive_location
          @system.mkdir
            target: options.install_dir
          @tools.extract
            source: tmp_archive_location
            target: options.install_dir
            preserve_owner: false
            strip: 1
          @system.link
            source: options.install_dir
            target: options.latest_dir

## Configuration

      @call header: 'Configuration', ->
        @system.link
          source: "#{options.latest_dir}/conf"
          target: options.conf_dir
        @system.remove
          shy: true
          target: "#{options.latest_dir}/bin/solr.in.sh"
        @system.link
          source: "#{options.conf_dir}/solr.in.sh"
          target: "#{options.latest_dir}/bin/solr.in.sh"
        @service.init
          header: 'Init Script'
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
          source: "#{__dirname}/../resources/cloud/solr.j2"
          target: '/etc/init.d/solr-cloud'
          local: true
          context: options
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          perm: '0750'


## Fix scripts
The zkCli.sh file, which enable solr to communicate with zookeeper
has to be fixe to use jdk 1.8.

      @file
        header: 'Fix zKcli script'
        target: "#{options.latest_dir}/server/scripts/cloud-scripts/zkcli.sh"
        write: [
          match: RegExp "^JVM=.*$", 'm'
          replace: "JVM=\"#{options.jre_home}/bin/java\""
        ]
        mode: 0o0750
        
        backup: false

## Layout

      @call header: 'Solr Layout', ->
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @system.mkdir
          target: options.user.home
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755


## SOLR HDFS Layout
Create HDFS solr user and its home directory

      @hdfs_mkdir
        header: 'HDFS Layout'
        if: options.hdfs?
        target: "/user/#{options.user.name}"
        user: options.user.name
        group: options.user.name
        mode: 0o0775
        krb5_user: options.hdfs.user

## Config

      @call header: 'Configure', ->
        options.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
        options.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of options.auth_opts
        writes = for k,v of options.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true
        @file.render
          header: 'Solr Environment'
          source: "#{__dirname}/../resources/cloud/solr.ini.sh.j2"
          target: "#{options.conf_dir}/solr.in.sh"
          context: options
          write: writes
          local: true
          backup: true
          eof: true
        @file.render
          header: 'Solr Config'
          source: "#{options.conf_source}"
          target: "#{options.conf_dir}/solr.xml"
          local: true
          backup: true
          eof: true
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
          context: options
        @system.link
          source: "#{options.conf_dir}/solr.xml"
          target: "#{options.user.home}/solr.xml"

## Kerberos

      @krb5.addprinc options.krb5.admin,
        unless_exists: options.spnego.keytab
        header: 'Kerberos SPNEGO'
        principal: options.spnego.principal
        randkey: true
        keytab: options.spnego.keytab
        uid: options.user.name
        gid: options.hadoop_group.name
      @system.execute
        header: 'SPNEGO'
        cmd: "su -l #{options.user.name} -c 'test -r #{options.spnego.keytab}'"
      @krb5.addprinc options.krb5.admin,
        header: 'Solr Super User'
        principal: options.admin_principal
        password: options.admin_password
        randkey: true
        uid: options.user.name
        gid: options.group.name
      @file.jaas
        header: 'Solr JAAS'
        target: "#{options.conf_dir}/solr-server.jaas"
        content:
          Client:
            principal: options.spnego.principal
            keyTab: options.spnego.keytab
            useKeyTab: true
            storeKey: true
            useTicketCache: true
        uid: options.user.name
        gid: options.group.name
      @krb5.addprinc options.krb5.admin,
        header: 'Solr Server User'
        principal: options.principal
        keytab: options.keytab
        randkey: true
        uid: options.user.name
        gid: options.group.name

## Bootstrap Zookeeper

      @system.execute
        header: 'Zookeeper bootstrap'
        cmd: """
        cd #{options.latest_dir}
        server/scripts/cloud-scripts/zkcli.sh -zkhost #{options.zkhosts} \
        -cmd bootstrap -solrhome #{options.user.home}
        """
        unless_exec: "zookeeper-client -server #{options.zk_connect} ls / | grep '#{options.zk_node}'"

## Enable Authentication and ACLs
For now we skip security configuration to solr when source is 'HDP'.
HDP has version 5.2.1 of solr, and security plugins are included from 5.3.0

      @system.execute
        header: "Upload Security conf"
        cmd: """
        cd #{options.latest_dir}
        server/scripts/cloud-scripts/zkcli.sh -zkhost #{options.zk_connect} \
        -cmd put /solr/security.json '#{JSON.stringify options.security}'
        """

## SSL

      @java.keystore_add
        keystore: options.keystore.target
        storepass: options.keystore.password
        key: "#{options.ssl.key.source}"
        cert: "#{options.ssl.cert.source}"
        keypass: options.keystore.password
        caname: "hadoop_root_ca"
        cacert: "#{options.ssl.cacert.source}"
        name: options.fqdn
        local: options.ssl.key.local
      @java.keystore_add
        keystore: options.truststore.target
        storepass: options.truststore.password
        caname: "hadoop_root_ca"
        cacert: "#{options.ssl.cacert.source}"
        local: options.ssl.cacert.local
      # not documented but needed when SSL
      @system.execute
        header: "Enable SSL Scheme"
        cmd: """
        cd #{options.latest_dir}
        server/scripts/cloud-scripts/zkcli.sh -zkhost #{options.zkhosts} \
        -cmd clusterprop -name urlScheme -val #{protocol}
        """

## Dependencies

    path = require 'path'
    mkcmd  = require '../../lib/mkcmd'
