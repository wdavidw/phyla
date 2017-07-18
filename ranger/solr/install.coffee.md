
# Solr Install

    module.exports = header: 'Solr Embedded Install', handler: ->
      {solr, ranger, ssl, realm} = @config.ryba
      return unless ranger.admin.solr_type is 'embedded'
      cluster_config = ranger.admin.cluster_config
      krb5 = @config.krb5_client.admin[realm]
      protocol = if solr.ssl.enabled then 'https' else 'http'

## Dependencies

      @call 'masson/core/krb5_client/wait'
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
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: solr.port, protocol: 'tcp', state: 'NEW', comment: "Solr Server #{protocol}" }
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
        directory: solr.conf_dir
        uid: solr.user.name
        gid: solr.group.name

## Packages

      @call header: 'Packages', ->
        @service
          name: 'lucidworks-hdpsearch'
        @system.chown
          target: '/opt/lucidworks-hdpsearch'
          uid: solr.user.name
          gid: solr.group.name

## Configuration

      @call header: 'Configuration', ->
        @system.link
          source: "#{solr.latest_dir}/conf"
          target: solr.conf_dir
        @system.remove
          shy: true
          target: "#{solr.latest_dir}/bin/solr.in.sh"
        @system.link
          source: "#{solr.conf_dir}/solr.in.sh"
          target: "#{solr.latest_dir}/bin/solr.in.sh"
        @service.init
          header: 'Init Script'
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          source: "#{__dirname}/../resources/solr/solr.j2"
          target: '/etc/init.d/solr'
          local: true
          context: @config

## Layout

      @call header: 'Solr Layout', ->
        @system.mkdir
          target: solr.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: solr.pid_dir
          uid: solr.user.name
          gid: solr.group.name
          perm: '0750'
        @system.mkdir
          target: solr.log_dir
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
        @system.mkdir
          target: solr.user.home
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755

## Config

      @call header: 'Configure', ->
        solr.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
        solr.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of solr.auth_opts
        writes = for k,v of solr.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true
        @file.render
          header: 'Solr Environment'
          source: "#{__dirname}/../resources/solr/solr.ini.sh.j2"
          target: "#{solr.conf_dir}/solr.in.sh"
          context: @config
          write: writes
          local: true
          backup: true
          eof: true
        @file.render
          header: 'Solr Config'
          source: solr.conf_source
          target: "#{solr.conf_dir}/solr.xml"
          uid: solr.user.name
          gid: solr.group.name
          mode: 0o0755
          context: {
            host: @config.host
            port: @config.ryba.solr.port
          }
          local: true
          backup: true
          eof: true
        @system.link
          source: "#{solr.conf_dir}/solr.xml"
          target: "#{solr.user.home}/solr.xml"

## Kerberos

      @krb5.addprinc krb5,
        header: 'Solr Server User'
        principal: solr.principal
        keytab: solr.keytab
        randkey: true
        uid: solr.user.name
        gid: solr.group.name

## SSL

      @java.keystore_add
        keystore: solr.ssl_keystore_path
        storepass: solr.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        key: "#{ssl.key}"
        cert: "#{ssl.cert}"
        keypass: solr.ssl_keystore_pwd
        name: @config.shortname
        local: true
      @java.keystore_add
        keystore: solr.ssl_trustore_path
        storepass: solr.ssl_keystore_pwd
        caname: "hadoop_root_ca"
        cacert: "#{ssl.cacert}"
        local: true

## Start

      @service.start
        header: 'Solr Start'
        name: 'solr'

## Prepare ranger_audits Collection/Core

      @system.mkdir
        target: "#{solr.user.home}/ranger_audits"
        uid: solr.user.name
        gid: solr.group.name
        mode: 0o0755
      @call
        header: 'Ranger Collection Solr Embedded'
      , ->
        @file.download
          source: "#{__dirname}/../resources/solr/elevate.xml"
          target: "#{solr.user.home}/ranger_audits/conf/elevate.xml" #remove conf if solr/cloud
        @file.download
          source: "#{__dirname}/../resources/solr/managed-schema"
          target: "#{solr.user.home}/ranger_audits/conf/managed-schema"
        @file.render
          source: "#{__dirname}/../resources/solr/solrconfig.xml"
          target: "#{solr.user.home}/ranger_audits/conf/solrconfig.xml"
          local: true
          context:
            retention_period: ranger.admin.audit_retention_period

## Create ranger_audits Collection/Core
The solrconfig.xml file corresponding to ranger_audits collection/core is rendered from
the resources, as it is not distributed in the apache community version.
The syntax of the command depends also from the solr type installed.
In solr/standalone core are used, whereas in solr/cloud collections are used.
We manage creating the ranger_audits core/collection in the three modes.

### Solr Embedded

      @wait.execute
        cmd: "curl -k --fail  \"#{if solr.ssl.enabled  then 'https://'  else 'http://'}#{@config.host}:#{@config.ryba.solr.port}/solr/admin/cores?wt=json\""
      @system.execute
        header: 'Create Ranger Core (embedded)'
        unless_exec: """
        curl -k --fail  \"#{if solr.ssl.enabled  then 'https://'  else 'http://'}#{@config.host}:#{@config.ryba.solr.port}/solr/admin/cores?core=ranger_audits&wt=json\" \
        | grep '\"schema\":\"managed-schema\"'
         """
        cmd: """
        #{solr.latest_dir}/bin/solr create_core -c ranger_audits \
        -d  #{solr.user.home}/ranger_audits
        """

## Dependencies

    path = require('path').posix
    mkcmd  = require '../../lib/mkcmd'
