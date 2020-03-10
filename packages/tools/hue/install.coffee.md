
# Hue Install

Here's how to uninstall Hue: `rpm -qa | grep hue | xargs sudo rpm -e`. This
article from december 2014 describe how to  [install the latest version of hue
on HDP](http://gethue.com/how-to-deploy-hue-on-hdp/).

## Metadata

    metadata =
      header: 'Hue Install'
      schema:
        banner_style:
          type: 'string'
        ca_bundle:
          type: 'string'
        clean_tmp:
          type: 'boolean'
        conf_dir:
          type: 'string'
        ini:
          type: 'object'
        group:
          "$ref": "/nikita/system/group"
  
## Action

    module.exports = header: metadata.header, schema: metadata.schema, handler: ({options}) ->

## Identities

By default, the "hue" package create the following entries:

```bash
cat /etc/passwd | grep hue
hue:x:494:494:Hue:/var/lib/hue:/sbin/nologin
cat /etc/group | grep hue
hue:x:494:
```

      # @system.group header: 'Group', options.group
      # @system.user header: 'User', options.user

## IPTables

| Service    | Port  | Proto | Parameter          |
|------------|-------|-------|--------------------|
| Hue Web UI | 8888  | http  | desktop.http_port  |

IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

      # @tools.iptables
      #   header: 'IPTables'
      #   rules: [
      #     { chain: 'INPUT', jump: 'ACCEPT', dport: options.ini['desktop']['http_port'], protocol: 'tcp', state: 'NEW', comment: "Hue Web UI" }
      #   ]
      #   if: options.iptables

## Packages

The packages "extjs-2.2-1" and "hue" are installed.

      # @call header: 'Dependencies', ->
      #   @service.install
      #     if: options.db.engine in ['mariadb', 'mysql']
      #     name: 'mariadb'
      #   @service.install
      #     if: options.db.engine in ['postgresql']
      #     name: 'postgresql'
      #   @service.install name for name in [
      #     'ant', 'asciidoc', 'cyrus-sasl-devel', 'cyrus-sasl-gssapi'
      #     'cyrus-sasl-plain', 'gcc', 'gcc-c++', 'krb5-devel', 'libffi-devel'
      #     'libxml2-devel', 'libxslt-devel', 'make', 'maven', 'mysql', 'mysql-devel',
      #     'openldap-devel', 'openssl-devel', 'python-devel', 'rsync', 'sqlite-devel', 'gmp-devel'
      #   ]
      #   @system.execute
      #     header: 'Node.js'
      #     unless_exec: 'command -v node'
      #     cmd: """
      #     yum install -y epel-release
      #     yum install -y nodejs
      #     """
      # @file.download
      #   header: 'Download'
      #   source: 'https://cdn.gethue.com/downloads/hue-4.6.0.tgz'
      #   target: '/tmp/hue-4.6.0.tgz'
      # @system.execute
      #   header: 'Extract'
      #   unless_exists: '/tmp/hue-4.6.0'
      #   cmd: """
      #   tar -xzf /tmp/hue-4.6.0.tgz -C /tmp/
      #   """
      # @system.execute
      #   header: 'Compile'
      #   unless_exists: '/usr/share/hue/build/env/bin/supervisor'
      #   cwd: '/tmp/hue-4.6.0'
      #   cmd: """
      #   rm -rf /usr/share/hue/
      #   PREFIX=/usr/share make install
      #   """

## Configure

Configure the "/etc/hue/conf" file following the [HortonWorks](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-2.html) 
recommandations. Merge the configuration object from "hdp.hue.ini" with the properties of the target file. 

      @file.ini
        header: 'Configure'
        target: "#{options.conf_dir}/hue.ini"
        content: options.ini
        merge: true
        parse: misc.ini.parse_multi_brackets
        stringify: misc.ini.stringify_multi_brackets
        separator: '='
        comment: '#'
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750

## Database

Setup the database hosting the Hue data. Currently two database providers are
implemented but Hue supports MySQL, PostgreSQL, and Oracle. Note, sqlite is 
the default database while mysql is the recommanded choice.

      @call header: 'DB', ->

Wait for database to listen

        @call '@rybajs/tools/db_admin/wait', once: true, options.wait_db_admin

Create the database hosting the Ambari data with restrictive user permissions.

        # @db.user options.db, database: null,
        #   header: 'User'
        #   if: options.db.engine in ['mariadb', 'mysql', 'postgresql']
        # @db.database options.db,
        #   header: 'Database'
        #   user: options.db.username
        #   if: options.db.engine in ['mariadb', 'mysql', 'postgresql']
        # @db.schema options.db,
        #   header: 'Schema'
        #   if: options.db.engine is 'postgresql'
        #   options:
        #     schema: options.db.schema or options.db.database
        #     database: options.db.database
        #     owner: options.db.username

Load the database with initial data

        # @db.query options.db,
        #   cmd: "show tables from #{options.db.database};"
        #   grep: 'auth_user'
        #   shy: true
        # @system.execute
        #   header: 'Init'
        #   unless: -> @status -1
        #   cmd: """
        #   su -l #{options.user.name} -c "/usr/share/hue/build/env/bin/hue syncdb --noinput && /usr/share/hue/build/env/bin/hue migrate"
        #   """
## SSL

      @call header: 'SSL IPA', ->
        @file
          header: 'Sync'
          target: "#{options.conf_dir}/import_ipa_cert.sh"
          mode: 0o0755
          content: """
          cp -rp /etc/ipa/cert.pem #{options.ini.desktop.ssl_certificate}
          cp -rp /etc/ipa/key.pem #{options.ini.desktop.ssl_private_key}
          cp -rp /etc/ipa/ca.crt #{options.ini.desktop.ssl_cacerts}
          chown #{options.user.name} \\
            #{options.ini.desktop.ssl_certificate} \\
            #{options.ini.desktop.ssl_private_key} \\
            #{options.ini.desktop.ssl_cacerts}
          """
          uid: "#{options.user.name}"
          gid: "#{options.group.name}"
          eof: true
          trap: true
        @tools.cron.add
          header: 'Cron'
          cmd: "#{options.conf_dir}/import_ipa_cert.sh"
          when: '0 5 * * *'
          user: "#{options.user.name}"
          exec: true
          backup: true

      return

## Kerberos

The principal for the Hue service is created and named after "hue/{host}@{realm}". inside
the "/etc/hue/conf/hue.ini" configuration file, all the composants myst be tagged with
the "security_enabled" property set to "true".

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: options.ini.desktop.kerberos.hue_principal
        randkey: true
        keytab: options.ini.desktop.kerberos.hue_keytab
        uid: options.user.name
        gid: options.group.name

## SSL Client

      @call header: 'SSL Client', ->
        ca_bundle = if options.ssl.client_ca then options.ca_bundle else ''
        @file
          target: "#{ca_bundle}"
          source: "#{options.ssl.client_ca}"
          local: true
          if: !!options.ssl.client_ca
        @service.init
          target: '/etc/init.d/hue'
          match: /^DAEMON="export REQUESTS_CA_BUNDLE='.*';\$DAEMON"$/m
          replace: "DAEMON=\"export REQUESTS_CA_BUNDLE='#{ca_bundle}';$DAEMON\""
          append: /^DAEMON=.*$/m
          mode: 0o755

## SSL Server

Upload and register the SSL certificate and private key respectively defined by
the "hdp.hue.ssl.certificate" and "hdp.hue.ssl.private_key"  configuration
properties. It follows the [official Hue Web Server
Configuration](http://gethue.com/docs-3.5.0/manual.html#_web_server_configuration).
The "hue" service is restarted if there was any  changes.

      @call header: 'SSL Server', ->
        @file.download
          source: options.ssl.certificate
          target: "#{options.conf_dir}/cert.pem"
          uid: options.user.name
          gid: options.group.name
        @file.download
          source: options.ssl.private_key
          target: "#{options.conf_dir}/key.pem"
          uid: options.user.name
          gid: options.group.name
        @file.ini
          target: "#{options.conf_dir}/hue.ini"
          content: desktop:
            ssl_certificate: "#{options.conf_dir}/cert.pem"
            ssl_private_key: "#{options.conf_dir}/key.pem"
          merge: true
          parse: misc.ini.parse_multi_brackets
          stringify: misc.ini.stringify_multi_brackets
          separator: '='
          comment: '#'
          
## Systemd Service

      @service.init
        header: 'Systemd Script'
        target: '/etc/systemd/system/hue.service'
        source: "#{__dirname}/assets/hue-systemd.j2"
        local: true
        # context: options: options
        uid: 'root'
        gid: 'root'
        mode: 0o0644

## Fix Banner

In the current version "2.5.1", the HTML of the banner is escaped.

      @call header: 'Fix Banner', ->
        @file
          target: '/usr/lib/hue/desktop/core/src/desktop/templates/login.mako'
          match: '${conf.CUSTOM.BANNER_TOP_HTML.get()}'
          replace: '${ conf.CUSTOM.BANNER_TOP_HTML.get() | n,unicode }'
          bck: true
        @file
          target: '/usr/lib/hue/desktop/core/src/desktop/templates/common_header.mako'
          write: [
            match: '${conf.CUSTOM.BANNER_TOP_HTML.get()}'
            replace: '${ conf.CUSTOM.BANNER_TOP_HTML.get() | n,unicode }'
            bck: true
          ,
            match: /\.banner \{([\s\S]*?)\}/
            replace: ".banner {#{options.banner_style}}"
            bck: true
            if: options.banner_style
          ]

## Clean Temp Files

Clean up the "/tmp" from temporary Hue directories. All the directories which
modified time are older than 10 days will be removed.

      @tools.cron.add
        header: 'Clean Temp Files'
        cmd: "find /tmp -maxdepth 1 -type d -mtime +10 -user #{options.user.name} -exec rm {} \\;",
        when: '0 */19 * * *'
        user: "#{options.user.name}"
        match: "\\/tmp .*-user #{options.user.name}"
        exec: true
        if: options.clean_tmp

## Dependencies

    misc = require '@nikitajs/core/lib/misc'

## Resources:   

*   [Official Hue website](http://gethue.com)
*   [Hortonworks instructions](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue.html)
