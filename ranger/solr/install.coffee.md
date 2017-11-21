
# Solr Install

    module.exports = header: 'Solr Embedded Install', handler: (options) ->
      return unless options.solr_type is 'embedded'

## Dependencies

      @call 'masson/core/krb5_client/wait', options.wait_krb5_client
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## IPTables

| Service      | Port  | Proto       | Parameter          |
|--------------|-------|-------------|--------------------|
| Solr Server  | 8983  | http        | port               |
| Solr Server  | 9983  | https       | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      protocol = if options.solr.ssl.enabled then 'https' else 'http'
      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.solr.port, protocol: 'tcp', state: 'NEW', comment: "Solr Server #{protocol}" }
        ]
        if: options.iptables

## Identities

      @system.group header: 'Group', options.solr.group
      @system.user header: 'User', options.solr.user

## Layout

      @system.mkdir
        target: options.solr.user.home
        uid: options.solr.user.name
        gid: options.solr.group.name
      @system.mkdir
        directory: options.solr.conf_dir
        uid: options.solr.user.name
        gid: options.solr.group.name

## Packages

      @call header: 'Packages', ->
        @service
          name: 'lucidworks-hdpsearch'
        @system.chown
          target: '/opt/lucidworks-hdpsearch'
          uid: options.solr.user.name
          gid: options.solr.group.name

## Configuration

      @call header: 'Configuration', ->
        @system.link
          source: "#{options.solr.latest_dir}/conf"
          target: options.solr.conf_dir
        @system.remove
          shy: true
          target: "#{options.solr.latest_dir}/bin/solr.in.sh"
        @system.link
          source: "#{options.solr.conf_dir}/solr.in.sh"
          target: "#{options.solr.latest_dir}/bin/solr.in.sh"
        @service.init
          header: 'Init Script'
          uid: options.solr.user.name
          gid: options.solr.group.name
          mode: 0o0755
          source: "#{__dirname}/../resources/solr/solr.j2"
          target: '/etc/init.d/solr'
          local: true
          context: options.solr

## Layout

      @call header: 'Solr Layout', ->
        @system.mkdir
          target: options.solr.pid_dir
          uid: options.solr.user.name
          gid: options.solr.group.name
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: options.solr.pid_dir
          uid: options.solr.user.name
          gid: options.solr.group.name
          perm: 0o0750
        @system.mkdir
          target: options.solr.log_dir
          uid: options.solr.user.name
          gid: options.solr.group.name
          mode: 0o0755
        @system.mkdir
          target: options.solr.user.home
          uid: options.solr.user.name
          gid: options.solr.group.name
          mode: 0o0755

## Config

      @call header: 'Configure', ->
        options.solr.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
        options.solr.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of options.solr.auth_opts
        writes = for k,v of options.solr.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true
        @file.render
          header: 'Solr Environment'
          source: "#{__dirname}/../resources/solr/solr.ini.sh.j2"
          target: "#{options.solr.conf_dir}/solr.in.sh"
          context: options.solr
          write: writes
          local: true
          backup: true
          eof: true
        @file.render
          header: 'Solr Config'
          source: options.solr.conf_source
          target: "#{options.solr.conf_dir}/solr.xml"
          uid: options.solr.user.name
          gid: options.solr.group.name
          mode: 0o0755
          context: {
            host: options.solr.fqdn
            port: options.solr.port
          }
          local: true
          backup: true
          eof: true
        @system.link
          source: "#{options.solr.conf_dir}/solr.xml"
          target: "#{options.solr.user.home}/solr.xml"

## Kerberos

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.solr.principal
        keytab: options.solr.keytab
        randkey: true
        uid: options.solr.user.name
        gid: options.solr.group.name

## SSL

      @call header: 'SSL', ->
        @java.keystore_add
          keystore: options.solr.ssl_keystore_path
          storepass: options.solr.ssl_keystore_pwd
          key: "#{options.ssl.key.source}"
          cert: "#{options.ssl.cert.source}"
          keypass: options.solr.ssl_keystore_pwd
          name: "#{options.ssl.key.name}"
          local: "#{options.ssl.key.local}"
        @java.keystore_add
          keystore: options.solr.ssl_keystore_path
          storepass: options.solr.ssl_keystore_pwd
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: "#{options.ssl.cacert.local}"
        @java.keystore_add
          keystore: options.solr.ssl_truststore_path
          storepass: options.solr.ssl_keystore_pwd
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: "#{options.ssl.cacert.local}"

## Start

      @service.start
        header: 'Start'
        name: 'solr'
      @system.execute.assert
        header: 'Assert'
        cmd: "curl -k --fail  \"#{if options.solr.ssl.enabled  then 'https://'  else 'http://'}#{options.fqdn}:#{options.solr.port}/solr/admin/cores?wt=json\""
        retry: 3
        sleep: 3000

## Prepare ranger_audits Collection/Core

      @system.mkdir
        target: "#{options.solr.user.home}/ranger_audits"
        uid: options.solr.user.name
        gid: options.solr.group.name
        mode: 0o0755
      @call
        header: 'Ranger Collection Solr Embedded'
      , ->
        @file.download
          source: "#{__dirname}/../resources/solr/elevate.xml"
          target: "#{options.solr.user.home}/ranger_audits/conf/elevate.xml" #remove conf if solr/cloud
        @file.download
          source: "#{__dirname}/../resources/solr/managed-schema"
          target: "#{options.solr.user.home}/ranger_audits/conf/managed-schema"
        @file.render
          source: "#{__dirname}/../resources/solr/solrconfig.xml"
          target: "#{options.solr.user.home}/ranger_audits/conf/solrconfig.xml"
          local: true
          context:
            retention_period: options.audit_retention_period

## Create ranger_audits Collection/Core

The solrconfig.xml file corresponding to ranger_audits collection/core is rendered from
the resources, as it is not distributed in the apache community version.
The syntax of the command depends also from the solr type installed.
In solr/standalone core are used, whereas in solr/cloud collections are used.
We manage creating the ranger_audits core/collection in the three modes.

### Solr Embedded

      @system.execute
        header: 'Create Core'
        unless_exec: """
        protocol='#{if options.solr.ssl.enabled then 'https' else 'http'}'
        exists_url="$protocol://#{options.fqdn}:#{options.solr.port}/solr/admin/cores?core=ranger_audits&wt=json"
        curl -k --fail $exists_url | grep '"schema":"managed-schema"'
        """
        cmd: """
        #{options.solr.latest_dir}/bin/solr create_core \
          -c ranger_audits \
          -d #{options.solr.user.home}/ranger_audits
        """
        code_skipped: 3
        retry: 3
        sleep: 3000
      @call -> process.exit

## Dependencies

    path = require('path').posix
    mkcmd  = require '../../lib/mkcmd'
