
# Solr Install

    module.exports = header: 'Solr Standalone Install', handler: ->
      {solr, realm} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm, hadoop_group} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]
      tmp_archive_location = "/var/tmp/@rybajs/metal/solr.tar.gz"
      protocol = if solr.single.ssl.enabled then 'https' else 'http'

## Dependencies

      @call 'masson/core/krb5_client/wait'
      @registry.register ['file', 'jaas'], '@rybajs/metal/lib/file_jaas'
      @registry.register 'hdfs_mkdir', '@rybajs/metal/lib/hdfs_mkdir'

## IPTables

| Service      | Port  | Proto       | Parameter          |
|--------------|-------|-------------|--------------------|
| Solr Server  | 8983  | http        | port               |
| Solr Server  | 9983  | https       | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: solr.single.port, protocol: 'tcp', state: 'NEW', comment: "Solr Server #{protocol}" }
        ]
        if: @config.iptables.action is 'start'

## Identities

      @system.group header: 'Group', solr.group
      @system.user header: 'User', solr.user

## Layout

      @system.mkdir
        target: solr.user.home
        uid: solr.user.name
        gid: solr.group.name
      @system.mkdir
        directory: solr.single.conf_dir
        uid: solr.user.name
        gid: solr.group.name

## Packages

Ryba support installing solr from apache official release or HDP Search repos.

      @call header: 'Packages', ->
        @call
          if:  solr.single.source is 'HDP'
        , ->
          @service
            name: 'lucidworks-hdpsearch'
          @system.chown
            if: solr.single.source is 'HDP'
            target: '/opt/lucidworks-hdpsearch'
            uid: solr.user.name
            gid: solr.group.name
        @call
          if: solr.single.source isnt 'HDP'
        , ->
          @file.download
            source: solr.single.source
            target: tmp_archive_location
          @system.mkdir
            target: solr.single.install_dir
          @tools.extract
            source: tmp_archive_location
            target: solr.single.install_dir
            preserve_owner: false
            strip: 1
          @system.link
            source: solr.single.install_dir
            target: solr.single.latest_dir

## Configuration

      @call header: 'Configuration', ->
        @system.link
          source: "#{solr.single.latest_dir}/conf"
          target: solr.single.conf_dir
        @system.remove
          shy: true
          target: "#{solr.single.latest_dir}/bin/solr.in.sh"
        @system.link
          source: "#{solr.single.conf_dir}/solr.in.sh"
          target: "#{solr.single.latest_dir}/bin/solr.in.sh"
        @service.init
          header: 'Init Script'
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          source: "#{__dirname}/../resources/standalone/solr.j2"
          target: '/etc/init.d/solr'
          local: true
          context: @config

## Layout

      @call header: 'Solr Layout', ->
        @system.mkdir
          target: solr.single.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: solr.single.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          perm: '0750'
        @system.mkdir
          target: solr.single.log_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @system.mkdir
          target: solr.user.home
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755

## SOLR HDFS Layout
Create HDFS solr user and its home directory

      @hdfs_mkdir
        if: solr.single.hdfs?
        header: 'HDFS Layout'
        target: "/user/#{solr.user.name}"
        user: solr.user.name
        group: solr.user.name
        mode: 0o0775
        krb5_user: @config.ryba.hdfs.krb5_user

## Config

      @call header: 'Configure', ->
        solr.single.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
        solr.single.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of solr.single.auth_opts
        writes = for k,v of solr.single.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true
        @file.render
          header: 'Solr Environment'
          source: "#{__dirname}/../resources/standalone/solr.ini.sh.j2"
          target: "#{solr.single.conf_dir}/solr.in.sh"
          context: @config
          write: writes
          local: true
          backup: true
          eof: true
        @file.render
          header: 'Solr Config'
          source: solr.single.conf_source
          target: "#{solr.single.conf_dir}/solr.xml"
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          context: {
            host: @config.host
            port: @config.ryba.solr.single.port
          }
          local: true
          backup: true
          eof: true
        @system.link
          source: "#{solr.single.conf_dir}/solr.xml"
          target: "#{solr.user.home}/solr.xml"

## Kerberos

      @krb5.addprinc krb5,
        header: 'Solr Server User'
        principal: solr.single.principal
        keytab: solr.single.keytab
        randkey: true
        uid: solr.user.name
        gid: solr.group.name

## SSL

      @java.keystore_add
        keystore: solr.single.ssl_keystore_path
        storepass: solr.single.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: solr.single.ssl_keystore_pwd
        name: options.hostname
        local: true
      @java.keystore_add
        keystore: solr.single.ssl_truststore_path
        storepass: solr.single.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local: true

## Dependencies

    path = require 'path'
    mkcmd  = require '../../lib/mkcmd'
