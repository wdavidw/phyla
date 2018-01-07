
# Knox Install

    module.exports = header: 'Knox Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## IPTables

| Service        | Port  | Proto | Parameter       |
|----------------|-------|-------|-----------------|
| Gateway        | 8443  | http  | gateway.port    |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.gateway_site['gateway.port'], protocol: 'tcp', state: 'NEW', comment: "Knox Gateway" }
        ]

## Packages

      @call header: 'Packages', ->
        @service name: 'knox'
        @hdp_select name: 'knox-server'
        # Fix autogen of master secret
        @call
          if: ->@status -2
        , ->
          @each  [
            '/usr/hdp/current/knox-server/data/security/master'
            '/usr/hdp/current/knox-server/data/security/keystores'
            '/usr/hdp/current/knox-server/conf/topologies/admin.xml'
            '/usr/hdp/current/knox-server/conf/topologies/sandbox.xml'
          ] , (options) ->
              @system.remove  target: options.key
        # Fix for the bug with rpm/deb packages. During installation of the package, they re-apply permissions to the folder
        @system.mkdir
          target: "#{options.log_dir}"
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd Script'
          target: '/etc/init.d/knox-server'
          source: "#{__dirname}/../resources/knox-server.j2"
          local: true
          context: options: options
          mode: 0o755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/knox-server.service'
            source: "#{__dirname}/../resources/knox-server-systemd.j2"
            local: true
            context: options: options
            mode: 0o0644
          @system.tmpfs
            if_os: name: ['redhat','centos'], version: '7'
            mount: "#{options.pid_dir}"
            uid: options.user.name
            gid: options.group.name
            perm: '0755'

## Configure

      @hconfigure
        header: 'Configure'
        target: "#{options.conf_dir}/gateway-site.xml"
        properties: options.gateway_site
        merge: true

      @file.render
        header: 'Knox Ldap Caching'
        target: "#{options.conf_dir}/ehcache.xml"
        source: "#{__dirname}/../resources/ehcache.j2"
        local: true
        context: options: options

## Env

We do not edit knox-env.sh because environnement variables are directly set
in the gateway.sh service script.

      @call header: 'Env', ->
        options.env.app_log_opts += " -D#{k}=#{v}" for k,v of options.log4jopts
        @file
          header: 'Env'
          target: "#{options.bin_dir}/gateway.sh"
          mode: 0o0755
          write: for k, v of options.env
            match: RegExp "^#{k.toUpperCase()}=.*$", 'img'
            replace: "#{k.toUpperCase()}=\"#{v}\""
            append: false

## Kerberos

      @call header: 'Kerberos', ->
        @krb5.addprinc options.krb5.admin,
          principal: options.krb5_user.principal
          randkey: true
          keytab: options.krb5_user.keytab
          uid: options.user.name
          gid: options.group.name
        @file.jaas
          target: options.gateway_site['java.security.auth.login.config']
          content: 'com.sun.security.jgss.initiate':
            principal: options.krb5_user.principal
            keyTab: options.krb5_user.keytab
            renewTGT: true
            doNotPrompt: true
            isInitiator: true
            useTicketCache: true
            client: true
          no_entry_check: true
          uid: options.user.name
          gid: options.group.name
          mode: 0o600

## Topologies

      @call header: 'Topologies', ->
        for nameservice, topology of options.topologies
          doc = builder.create 'topology', version: '1.0', encoding: 'UTF-8'
          gateway = doc.ele 'gateway' if topology.providers?
          for role, p of topology.providers
            provider = gateway.ele 'provider'
            provider.ele 'role', role
            provider.ele 'name', p.name
            provider.ele 'enabled', if p.enabled? then "#{p.enabled}" else 'true'
            if typeof p.config is 'object'
              for name in Object.keys(p.config).sort()
                if p.config[name]
                  param = provider.ele 'param'
                  param.ele 'name', name
                  param.ele 'value', p.config[name]
          for role, url_params of topology.services
            unless url_params is false
              service = doc.ele 'service'
              service.ele 'role', role.toUpperCase()
              if Array.isArray url_params then for u in url_params
                service.ele 'url', u
              else if typeof url_params is 'object'
                service.ele 'url',url_params.url
                if url_params.params? then for param,value of url_params.params
                  service.ele 'param', param
                  service.ele 'value', value
              else if url_params not in [null, ''] then service.ele 'url', url_params
          @file
            target: "#{options.conf_dir}/topologies/#{nameservice}.xml"
            content: doc.end pretty: true
            backup: true
            eof: true

          @file.render
            target: "#{options.conf_dir}/#{nameservice}-ehcache.xml"
            source: "#{__dirname}/../resources/ehcache.j2"
            local: true
            context: nameservice:nameservice

## Master Key

      @call
        header: 'Create Keystore'
        unless_exists: '/usr/hdp/current/knox-server/data/security/master'
      , (_, callback) ->
        ssh = @ssh options.ssh
        ssh.shell (err, stream) =>
          stream.write "su -l #{options.user.name} -c '/usr/hdp/current/knox-server/bin/knoxcli.sh create-master'\n"
          stream.on 'data', (data, extended) ->
            if /Enter master secret/.test data then stream.write "#{options.ssl.keystore.password}\n"
            if /Master secret is already present on disk/.test data then callback null, false
            else if /Master secret has been persisted to disk/.test data then callback null, true
          stream.on 'exit', -> callback Error 'Exit before end'

      @call header: 'Store Password', ->
        # Create alias to store password used in topology
        for alias,password of options.realm_passwords then do (alias,password) =>
          nameservice=alias.split("-")[0]
          @system.execute
            cmd: "/usr/hdp/current/knox-server/bin/knoxcli.sh create-alias #{alias} --cluster #{nameservice} --value #{password}"

## SSL

      @call header: 'SSL Server', ->
        
        # tmp_location = "/var/tmp/ryba/knox_ssl"
        # @file.download
        #   source: options.ssl.cacert
        #   target: "#{tmp_location}/cacert"
        #   mode: 0o0600
        #   shy: true
        # @file.download
        #   source: options.ssl.cert
        #   target: "#{tmp_location}/cert"
        #   mode: 0o0600
        #   shy: true
        # @file.download
        #   source: options.ssl.key
        #   target: "#{tmp_location}/key"
        #   mode: 0o0600
        #   shy: true
        # @java.keystore_add
        #   keystore: '/usr/hdp/current/knox-server/data/security/keystores/gateway.jks'
        #   storepass: options.ssl.storepass
        #   caname: "hadoop_root_ca"
        #   cacert: "#{tmp_location}/cacert"
        #   key: "#{tmp_location}/key"
        #   cert: "#{tmp_location}/cert"
        #   keypass: options.ssl.keypass
        #   name: 'gateway-identity'
        @java.keystore_add
          keystore: options.ssl.keystore.target
          storepass: options.ssl.keystore.password
          key: options.ssl.key.source
          cert: options.ssl.cert.source
          keypass: options.ssl.keystore.keypass
          name: options.ssl.key.name
          local:  options.ssl.key.local
        @java.keystore_add
          keystore: options.ssl.keystore.target
          storepass: options.ssl.keystore.password
          caname: options.ssl.truststore.caname
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local
        @system.execute
          if: -> @status -1
          cmd: "/usr/hdp/current/knox-server/bin/knoxcli.sh create-alias gateway-identity-passphrase --value #{options.ssl.keystore.keypass}"

Knox use Shiro for LDAP authentication and Shiro cannot be configured for 
unsecure SSL.
With LDAPS, the certificate must be imported into the JRE's keystore for the
client to connect to openldap.

        @java.keystore_add
          keystore: "#{options.jre_home or options.java_home}/lib/security/cacerts"
          storepass: 'changeit'
          caname: options.ssl.truststore.caname
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local
        # @system.remove
        #   target: "#{tmp_location}/cacert"
        #   shy: true
        # @system.remove
        #   target: "#{tmp_location}/cert"
        #   shy: true
        # @system.remove
        #   target: "#{tmp_location}/key"
        #   shy: true

## Log4j

      @file
        header: 'Log4J Properties'
        target: "#{options.conf_dir}/gateway-log4j.properties"
        source: "#{__dirname}/../resources/gateway-log4j.properties"
        local: true
        write: for k, v of options.log4j
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true

## Dependencies

    builder = require 'xmlbuilder'
