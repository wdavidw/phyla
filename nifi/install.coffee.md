
# NiFi Install

    module.exports = header: 'NiFi Install', handler: (options) ->
      protocol = if options.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'

      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
        @system.mkdir
          target: '/var/run/nifi'
          uid: options.user.name
          gid: options.group.name

## IPTables

  | Service    | Port  | Proto  | Parameter                                   |
  |------------|-------|--------|---------------------------------------------|
  | nifi       | 9750  | tcp    | nifi.web.http.port                          |
  | nifi       | 9760  | tcp    | nifi.web.https.port                         |
  | nifi       | 9870  | tcp    | nifi.cluster.node.protocol.port             |
  | nifi       | 9871  | tcp    | nifi.cluster.manager.protocol.port          |


      rules = [
        { chain: 'INPUT', jump: 'ACCEPT', dport: options.properties["nifi.web.#{protocol}.port"], protocol: 'tcp', state: 'NEW', comment: "NiFi WebUI port" }
      ]
      if options.properties['nifi.cluster.is.node'] is 'true'
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: options.properties['nifi.cluster.node.protocol.port'], protocol: 'tcp', state: 'NEW', comment: "NiFi Node port" }
      if options.properties['nifi.cluster.is.manager'] is 'true'
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: options.properties['nifi.cluster.manager.protocol.port'], protocol: 'tcp', state: 'NEW', comment: "NiFi Manager port" }
      if options.properties['nifi.cluster.protocol.use.multicast'] is 'true'
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: options.properties['nifi.cluster.protocol.multicast.port'], protocol: 'tcp', state: 'NEW', comment: "NiFi Multicast port" }
      if options.properties['nifi.remote.input.socket.port'] and options.properties['nifi.remote.input.socket.port'] isnt ''
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: options.properties['nifi.remote.input.socket.port'], protocol: 'tcp', state: 'NEW', comment: "NiFi S2S RAW socket port" }
      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: rules

## Service

      @call header: 'Packages', ->
        @service
          name: 'nifi'
        @system.execute
          header: 'fix permissions'
          cmd: """
          chown -R #{options.user.name}:#{options.group.name} /usr/hdf/current/nifi/lib
          """
          if: -> @status -1
        @system.chown
          target: '/var/run/nifi'
          uid: options.user.name
          gid: options.group.name
        @service.init
          header: 'rc.d'
          target: '/etc/init.d/nifi'
          source: "#{__dirname}/resources/nifi.j2"
          context: options
          local: true
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: '/var/run/nifi'
          uid: options.user.name
          gid: options.group.name
          perm: '0750'

## Env

      @file.render
        header: 'Env'
        target: '/usr/hdf/current/nifi/bin/nifi-env.sh'
        source: "#{__dirname}/resources/nifi-env.sh.j2"
        context: options
        local: true
        backup: true

## Keep JAVA_HOME

NiFi service script use sudo to impersonate. Since, sudo must keep JAVA_HOME env
var to work.

      @call header: 'sudo keep JAVA_HOME', ->
        @system.chmod
          target: '/etc/sudoers'
          mode: 0o640
        @file
          target: '/etc/sudoers'
          write: [
            match: 'Defaults    env_keep += "JAVA_HOME"'
            replace: 'Defaults    env_keep += "JAVA_HOME"'
            place_before: /Defaults +env_keep \+=/
            append: true
          ]
          backup: true

## Login Identity Providers

Describe where to get the user authentication information from.

      @call header: 'Login identity provider', ->
        providers = builder.create('loginIdentityProviders').dec '1.0', 'UTF-8', true
        {ldap_provider, krb5_provider} = options.login_providers
        if ldap_provider?
          ldap_node = providers.ele 'provider'
          ldap_node.ele 'identifier', 'ldap-provider'
          ldap_node.ele 'class', 'org.apache.nifi.ldap.LdapProvider'
          ldap_node.ele 'property', name: 'Authentication Strategy', ldap_provider.auth_strategy
          ldap_node.ele 'property', name: 'Manager DN', ldap_provider.manager_dn
          ldap_node.ele 'property', name: 'Manager Password', ldap_provider.manager_pwd
          ldap_node.ele 'property', name: 'TLS - Keystore', ldap_provider.tls_keystore
          ldap_node.ele 'property', name: 'TLS - Keystore Password', ldap_provider.tls_keystore_pwd
          ldap_node.ele 'property', name: 'TLS - Keystore Type', ldap_provider.tls_keystore_type
          ldap_node.ele 'property', name: 'TLS - Truststore', ldap_provider.tls_truststore
          ldap_node.ele 'property', name: 'TLS - Truststore Password', ldap_provider.tls_truststore_pwd
          ldap_node.ele 'property', name: 'TLS - Truststore Type', ldap_provider.tls_truststore_type
          ldap_node.ele 'property', name: 'TLS - Client Auth', ldap_provider.tls_client_auth
          ldap_node.ele 'property', name: 'TLS - Protocol', ldap_provider.tls_truststore_protocol
          ldap_node.ele 'property', name: 'TLS - Shutdown Gracefully', 'false'
          ldap_node.ele 'property', name: 'Referral Strategy', ldap_provider.ref_strategy
          ldap_node.ele 'property', name: 'Connect Timeout', '10 secs'
          ldap_node.ele 'property', name: 'Read Timeout', '10 secs'
          ldap_node.ele 'property', name: 'Url', ldap_provider.url
          ldap_node.ele 'property', name: 'User Search Base', ldap_provider.usr_search_base
          ldap_node.ele 'property', name: 'User Search Filter', ldap_provider.usr_search_filter
          ldap_node.ele 'property', name: 'Authentication Expiration', '12 hours'
        if krb5_provider?
          krb_node = providers.ele 'provider'
          krb_node.ele 'identifier', 'kerberos-provider'
          krb_node.ele 'class', 'org.apache.nifi.kerberos.KerberosProvider'
          krb_node.ele 'property', name: 'Default Realm', options.login_providers.krb5_provider.realm
          krb_node.ele 'property', name: 'Kerberos Config File', options.properties['nifi.kerberos.krb5.file']
          krb_node.ele 'property', name: 'Authentication Expiration', '10 hours'
          @krb5.addprinc options.krb5.admin,
            header: 'Kerberos SPNEGO'
            principal: options.properties['nifi.kerberos.service.principal']
            keytab: options.properties['nifi.kerberos.keytab.location']
            randkey: true
          @krb5.addprinc options.krb5.admin,
            header: 'Kerberos Admin'
            principal: options.admin.krb5_principal
            password: options.admin.krb5_password
        content = providers.end pretty: true
        @file
          target: options.properties['nifi.login.identity.provider.configuration.file']
          content: content
          uid: options.user.name
          gid: options.group.name
          backup: true

## Authorization

      @call header: 'Authorizers', ->
        providers = builder.create('authorizers').dec '1.0', 'UTF-8', true
        {file_provider} = options.authorizers
        if file_provider?
          file_node = providers.ele 'authorizer'
          file_node.ele 'identifier', 'file-provider'
          file_node.ele 'class', 'org.apache.nifi.authorization.FileAuthorizer'
          file_node.ele 'property', name: 'Authorizations File', file_provider['authorizations_file']
          file_node.ele 'property', name: 'Users File', file_provider['users_file']
          file_node.ele 'property', name: 'Initial Admin Identity', file_provider['initial_admin_identity']
          for node, i in file_provider['nodes_identities']
            file_node.ele 'property', name: "Node Identity #{i+1}", node
          @file.touch
            target: file_provider['authorizations_file']
            uid: options.user.name
            gid: options.group.name
          @file
            header: 'initial authorizations file'
            if: -> @status -1
            target: file_provider['authorizations_file']
            content: builder.create('authorizations').dec('1.0', 'UTF-8', true).end pretty: true
            eof: true
          @file.touch
            target: file_provider['users_file']
            uid: options.user.name
            gid: options.group.name
          @file
            header: 'initial users file'
            if: -> @status -1
            target: file_provider['users_file']
            content: builder.create('tenants').dec('1.0', 'UTF-8', true).end pretty: true
            eof: true
        @file
          target: options.properties['nifi.authorizer.configuration.file']
          content: providers.end pretty: true
          uid: options.user.name
          gid: options.group.name
          backup: true

## Cluster State Provider

Describes where the NiFi server store its internal states.
By default it is a local file, but in cluster mode, it uses zookeeper.

      @call header: 'State providers', ->
        providers = builder.create('stateManagement').dec '1.0', 'UTF-8', true
        local_node = providers.ele 'local-provider'
        local_node.ele 'id', 'local-provider'
        local_node.ele 'class', 'org.apache.nifi.controller.state.providers.local.WriteAheadLocalStateProvider'
        local_node.ele 'property', name: 'Directory', "#{options.user.home}/state/local"
        cluster_node = providers.ele 'cluster-provider'
        cluster_node.ele 'id', 'zk-provider'
        cluster_node.ele 'class', 'org.apache.nifi.controller.state.providers.zookeeper.ZooKeeperStateProvider'
        cluster_node.ele 'property', name: 'Connect String', options.properties['nifi.zookeeper.connect.string']
        cluster_node.ele 'property', name: 'Root Node', options.properties['nifi.zookeeper.root.node']
        cluster_node.ele 'property', name: 'Session Timeout', '30 seconds'
        cluster_node.ele 'property', name: 'Access Control', 'CreatorOnly'
        content = providers.end pretty: true
        @file
          target: options.properties['nifi.state.management.configuration.file']
          content: content
          uid: options.user.name
          gid: options.group.name
          backup: true

## Environment

      @file.render
        header: 'Bootstrap Conf'
        target: "#{options.conf_dir}/bootstrap.conf"
        source: "#{__dirname}/resources/bootstrap.conf.j2"
        context: nifi
        local: true
        eof: true
        backup: true

## JAAS

      @krb5.addprinc options.krb5.admin,
        header: 'Zookeeper Kerberos'
        principal: options.krb5_principal
        randkey: true
        keytab: options.krb5_keytab
        uid: options.user.name
        gid: options.group.name
      @file.jaas
        header: 'Zookeeper JAAS'
        target: "#{options.conf_dir}/nifi-zookeeper.jaas"
        content: Client:
          principal: options.krb5_principal
          keyTab: options.krb5_keytab
        uid: options.user.name
        gid: options.group.name
        mode: 0o600

## Configuration

      @file.properties
        header: 'NiFi properties'
        target: "#{options.conf_dir}/nifi.properties"
        content: options.properties
        backup: true
        eof: true

## SSL

      @call header: 'SSL', retry: 0, if: (-> options.properties['nifi.cluster.protocol.is.secure'] is 'true'), ->
        # Client: import certificate to all hosts
        @java.keystore_add
          keystore: options.properties['nifi.security.truststore']
          storepass: options.properties['nifi.security.truststorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: options.ssl.cacert.local
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          keystore: options.properties['nifi.security.keystore']
          storepass: options.properties['nifi.security.keystorePasswd']
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          key: "#{options.ssl.key.source}"
          cert: "#{options.ssl.cert.source}"
          keypass: options.properties['nifi.security.keyPasswd']
          name: options.shortname
          local: options.ssl.key.local
        # CA is commented as it is already handled in previous action above
        # @java.keystore_add
        #   keystore: options.properties['nifi.security.keystore']
        #   storepass: options.properties['nifi.security.keystorePasswd']
        #   caname: "hadoop_root_ca"
        #   cacert: "#{ssl.cacert}"
        #   local: true

# Notifications

      @file.download
        header: 'Services Notifications'
        target: "#{options.conf_dir}/bootstrap-notification-services.xml"
        source: "#{__dirname}/resources/bootstrap-notification-services.xml"

# Logs

      @file.render
        header: 'Log Configuration'
        target: "#{options.conf_dir}/logback.xml"
        source: "#{__dirname}/resources/logback.xml.j2"
        local: true
        context: options

## Additional Libs

      @call header: 'Additional Libs', if: options.custom_libs_dir.length, ->
        fs.readdir options.custom_libs_dir, (err, files) =>
          for lib in files
            @file.download
              target: "/usr/hdf/current/nifi/lib/#{lib}"
              source: "#{options.custom_libs_dir}/#{lib}"
              local: true

# User limits

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits
s
# Data Directories

      @system.mkdir
        header: 'Data directories layout'
        target: options.data_dirs
        uid: options.user.name
        gid: options.group.name
        mode: 0o751

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    builder = require 'xmlbuilder'
    fs = require 'fs'
