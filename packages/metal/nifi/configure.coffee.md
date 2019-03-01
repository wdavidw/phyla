
# NiFi Configure

    module.exports = (service) ->
      options = service.options

      # Set it to true if both hdf and hdp are installed on the cluster
      options.hdf_hdp ?= false
      zk_hosts = service.deps.zookeeper_server.filter( (srv) -> srv.options.config['peerType'] is 'participant')

## Environment

      options.conf_dir ?= '/etc/nifi/conf'
      options.log_dir ?= '/var/log/nifi'

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'nifi'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'nifi'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.comment ?= 'NiFi User'
      options.user.home ?= '/var/lib/nifi'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= 10000

## Configuration

      #Misc
      options.fqdn ?= service.node.fqdn
      options.shortname ?= service.node.hostname
      options.iptables ?= !!service.deps.iptables and service.deps.iptables.action is 'start'
      options.properties ?= {}
      options.properties['nifi.version'] ?= '1.2.0.3.0.0.0-453'
      options.properties['nifi.flow.configuration.file'] ?= "#{options.user.home}/flow.xml.gz"
      options.properties['nifi.flow.configuration.archive.dir'] ?= "#{options.user.home}/archive"
      options.properties['nifi.flowcontroller.autoResumeState'] ?= 'true'
      options.properties['nifi.flowcontroller.graceful.shutdown.period'] ?= '10 sec'
      options.properties['nifi.flowservice.writedelay.interval'] ?= '500 ms'
      options.properties['nifi.administrative.yield.duration'] ?= '30 sec'
      # If a component has no work to do (is "bored"), how long should we wait before checking again for work?'
      options.properties['nifi.bored.yield.duration'] ?= '10 millis'
      # timeout [properties][nifi-properties] before node disconnect
      options.properties['nifi.cluster.node.read.timeout'] ?= '15 sec'
      options.properties['nifi.authorizer.configuration.file'] ?= "#{options.conf_dir}/authorizers.xml"
      options.properties['nifi.login.identity.provider.configuration.file'] ?= "#{options.conf_dir}/login-identity-providers.xml"
      options.properties['nifi.templates.directory'] ?= "#{options.user.home}/templates"
      options.properties['nifi.ui.banner.text'] ?= ''
      options.properties['nifi.ui.autorefresh.interval'] ?= '30 sec'
      options.properties['nifi.nar.library.directory'] ?= '/usr/hdf/current/nifi/lib'
      options.properties['nifi.nar.working.directory'] ?= "#{options.user.home}/work/nar/"
      options.properties['nifi.documentation.working.directory'] ?= "#{options.user.home}/work/docs/components"

## State Management

      options.properties['nifi.state.management.configuration.file'] ?= "#{options.conf_dir}/state-management.xml"
      # The ID of the local state provider
      options.properties['nifi.state.management.provider.local'] ?= 'local-provider'
      # The ID of the cluster-wide state provider. This will be ignored if NiFi is not clustered but must be populated if running in a cluster.
      options.properties['nifi.state.management.provider.cluster'] ?= 'zk-provider'
      # Specifies whether or not this instance of NiFi should run an embedded ZooKeeper server
      options.properties['nifi.state.management.embedded.zookeeper.start'] ?= 'false'
      # Properties file that provides the ZooKeeper properties to use if <nifi.state.management.embedded.zookeeper.start> is set to true
      options.properties['nifi.state.management.embedded.zookeeper.properties'] ?= "#{options.conf_dir}/zookeeper.properties"

## H2 Settings

      options.properties['nifi.database.directory'] ?= "#{options.user.home}/database_repository"
      options.properties['nifi.h2.url.append'] ?= ';LOCK_TIMEOUT=25000;WRITE_DELAY=0;AUTO_SERVER=FALSE'

## Flow Configuration

      options.properties['nifi.flow.configuration.archive.enabled'] ?= 'true'
      options.properties['nifi.flow.configuration.archive.max.time'] ?= '30 days'
      options.properties['nifi.flow.configuration.archive.max.storage'] ?= '500 MB'
      # FlowFile Repository
      options.properties['nifi.flowfile.repository.implementation'] ?= 'org.apache.nifi.controller.repository.WriteAheadFlowFileRepository'
      options.properties['nifi.flowfile.repository.directory'] ?= "#{options.user.home}/flowfile_repository"
      options.properties['nifi.flowfile.repository.partitions'] ?= '256'
      options.properties['nifi.flowfile.repository.checkpoint.interval'] ?= '2 mins'
      options.properties['nifi.flowfile.repository.always.sync'] ?= 'false'

## Swap Configuration

      options.properties['nifi.swap.manager.implementation'] ?= 'org.apache.nifi.controller.FileSystemSwapManager'
      options.properties['nifi.queue.swap.threshold'] ?= '20000'
      options.properties['nifi.swap.in.period'] ?= '5 sec'
      options.properties['nifi.swap.in.threads'] ?= '1'
      options.properties['nifi.swap.out.period'] ?= '5 sec'
      options.properties['nifi.swap.out.threads'] ?= '4'

## Content Configuration

      options.properties['nifi.content.repository.implementation'] ?= 'org.apache.nifi.controller.repository.FileSystemRepository'
      # the content repository should be in dedicated folders.
      # if some content repositories are already configured, ryba considers that the default is disabled
      # administrator can still enable it using 'nifi.content.repository.directory.default' property
      options.use_content_default ?= true
      for k in Object.keys options.properties
        options.use_content_default = false if k.indexOf 'nifi.content.repository.directory.' isnt -1
      options.properties['nifi.content.repository.directory.default'] ?= "#{options.user.home}/content_repository" if options.use_content_default
      options.properties['nifi.content.claim.max.appendable.size'] ?= '10 MB'
      options.properties['nifi.content.claim.max.flow.files'] ?= '100'
      options.properties['nifi.content.repository.archive.max.retention.period'] ?= '12 hours'
      options.properties['nifi.content.repository.archive.max.usage.percentage'] ?= '50%'
      options.properties['nifi.content.repository.archive.enabled'] ?= 'true'
      options.properties['nifi.content.repository.always.sync'] ?= 'false'
      options.properties['nifi.content.viewer.url'] ?= '/nifi-content-viewer/'

## Provenance Configuration

      options.properties['nifi.provenance.repository.implementation'] ?= 'org.apache.nifi.provenance.PersistentProvenanceRepository'
      # the content repository should be in dedicated folders.
      # if some content repositories are already configured, ryba considers that the default is disabled
      # administrator can still enable it using 'nifi.content.repository.directory.default' property
      options.use_provenance_default ?= true
      for k in Object.keys options.properties
        options.use_provenance_default = false if k.indexOf 'nifi.provenance.repository.directory.' isnt -1
      options.properties['nifi.provenance.repository.directory.default'] ?= "#{options.user.home}/provenance_repository" if options.use_provenance_default
      options.properties['nifi.provenance.repository.max.storage.time'] ?= '24 hours'
      options.properties['nifi.provenance.repository.max.storage.size'] ?= '1 GB'
      options.properties['nifi.provenance.repository.rollover.time'] ?= '30 secs'
      options.properties['nifi.provenance.repository.rollover.size'] ?= '100 MB'
      options.properties['nifi.provenance.repository.query.threads'] ?= '2'
      options.properties['nifi.provenance.repository.index.threads'] ?= '1'
      options.properties['nifi.provenance.repository.compress.on.rollover'] ?= 'true'
      options.properties['nifi.provenance.repository.always.sync'] ?= 'false'
      options.properties['nifi.provenance.repository.journal.count'] ?= '16'
      # Comma-separated list of fields. Fields that are not indexed will not be searchable. Valid fields are: 
      # EventType, FlowFileUUID, Filename, TransitURI, ProcessorID, AlternateIdentifierURI, Relationship, Details
      options.properties['nifi.provenance.repository.indexed.fields'] ?= 'EventType, FlowFileUUID, Filename, ProcessorID, Relationship'
      # FlowFile Attributes that should be indexed and made searchable.  Some examples to consider are filename, uuid, mime.type
      options.properties['nifi.provenance.repository.indexed.attributes'] ?= ''
      # Large values for the shard size will result in more Java heap usage when searching the Provenance Repository
      # but should provide better performance
      options.properties['nifi.provenance.repository.index.shard.size'] ?= '500 MB'
      # Indicates the maximum length that a FlowFile attribute can be when retrieving a Provenance Event from
      # the repository. If the length of any attribute exceeds this value, it will be truncated when the event is retrieved.
      options.properties['nifi.provenance.repository.max.attribute.length'] ?= '65536'
      # Volatile Provenance Respository Properties
      options.properties['nifi.provenance.repository.buffer.size'] ?= '100000'

## Component Status Repository

      options.properties['nifi.components.status.repository.implementation'] ?= 'org.apache.nifi.controller.status.history.VolatileComponentStatusRepository'
      options.properties['nifi.components.status.repository.buffer.size'] ?= '1440'
      options.properties['nifi.components.status.snapshot.frequency'] ?= '1 min'

## Site to site properties

      options.properties['nifi.remote.input.socket.host'] ?= service.node.fqdn
      # Set a specific port in order to use RAW socket as transport protocol for Site-to-Site
      options.properties['nifi.remote.input.socket.port'] ?= ''

## Web Properties

      options.properties['nifi.web.war.directory'] ?= '/usr/hdf/current/nifi/lib'
      options.properties['nifi.web.jetty.working.directory'] ?= "#{options.user.home}/work/jetty"
      options.properties['nifi.web.jetty.threads'] ?= '200'

## Common Properties

      # cluster common properties (cluster manager and nodes must have same values) #
      options.properties['nifi.cluster.protocol.heartbeat.interval'] ?= '5 sec'
      options.properties['nifi.cluster.protocol.socket.timeout'] ?= '30 sec'
      options.properties['nifi.cluster.protocol.connection.handshake.timeout'] ?= '45 sec'
      # if multicast is used, then nifi.cluster.protocol.multicast.xxx properties must be configured #
      options.properties['nifi.cluster.protocol.use.multicast'] ?= 'false'
      options.properties['nifi.cluster.protocol.multicast.address'] ?= ''
      options.properties['nifi.cluster.protocol.multicast.port'] ?= '9872'
      options.properties['nifi.cluster.protocol.multicast.service.broadcast.delay'] ?= '500 ms'
      options.properties['nifi.cluster.protocol.multicast.service.locator.attempts'] ?= '3'
      options.properties['nifi.cluster.protocol.multicast.service.locator.attempts.delay'] ?= '1 sec'
      # cluster node properties (only configure for cluster nodes) #
      options.properties['nifi.cluster.is.node'] ?= 'true'
      if options.properties['nifi.cluster.is.node'] is 'true'
        options.properties['nifi.cluster.node.address'] ?= service.node.fqdn
        options.properties['nifi.cluster.node.protocol.port'] ?= '9870'
        options.properties['nifi.cluster.node.protocol.threads'] ?= '10'
        options.properties['nifi.zookeeper.connect.string'] ?= zk_hosts.map( (srv) -> "#{srv.node.fqdn}:#{srv.options.config['clientPort']}").join ','
        options.properties['nifi.zookeeper.root.node'] ?= '/nifi'
        options.properties['nifi.cluster.request.replication.claim.timeout'] ?= '15 sec'
      options.properties['nifi.cluster.is.manager'] ?= 'false'
      if options.properties['nifi.cluster.is.manager'] is 'true'
        options.properties['nifi.cluster.manager.address'] ?= service.node.fqdn
        options.properties['nifi.cluster.manager.protocol.port'] ?= '9871'
        options.properties['nifi.cluster.manager.node.firewall.file'] ?= ''
        options.properties['nifi.cluster.manager.node.event.history.size'] ?= '10'
        options.properties['nifi.cluster.manager.node.api.connection.timeout'] ?= '30 sec'
        options.properties['nifi.cluster.manager.node.api.read.timeout'] ?= '30 sec'
        options.properties['nifi.cluster.manager.node.api.request.threads'] ?= '10'
        options.properties['nifi.cluster.manager.flow.retrieval.delay'] ?= '5 sec'
        options.properties['nifi.cluster.manager.protocol.threads'] ?= '10'
        options.properties['nifi.cluster.manager.safemode.duration'] ?= '0 sec'
      options.properties['nifi.cluster.flow.election.max.wait.time'] ?= '5 mins'
      options.properties['nifi.cluster.flow.election.max.candidates'] ?= "#{service.deps.nifi.length}"

## Security

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      #Sensitive value encryption
      options.properties['nifi.sensitive.props.key'] ?= '' #'nifi_master_secret_123'
      options.properties['nifi.sensitive.props.algorithm'] ?= 'PBEWITHMD5AND256BITAES-CBC-OPENSSL'
      options.properties['nifi.sensitive.props.provider'] ?= 'BC'
      # Kerberos
      if service.deps.hadoop_core[0].options.core_site['hadoop.security.authentication'] is 'kerberos'
        options.properties['nifi.kerberos.krb5.file'] ?= '/etc/krb5.conf'

## SSL

        options.ssl = mixme service.deps.ssl?.options, options.ssl
        options.ssl.enabled ?= !!service.deps.ssl
        options.truststore ?= {}
        options.keystore ?= {}
        if options.ssl.enabled
          throw Error "Required Option: ssl.cert" if  not options.ssl.cert
          throw Error "Required Option: ssl.key" if not options.ssl.key
          throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
          options.truststore.target ?= "#{options.conf_dir}/truststore"
          throw Error "Required Property: truststore.password" if not options.truststore.password
          options.keystore.target ?= "#{options.conf_dir}/keystore"
          throw Error "Required Property: keystore.password" if not options.keystore.password
          options.truststore.caname ?= 'hadoop_root_ca'
      options.properties['nifi.cluster.protocol.is.secure'] ?= 'true'
      if options.properties['nifi.cluster.protocol.is.secure'] is 'true'
        options.properties['nifi.web.http.host'] = ''
        options.properties['nifi.web.http.port'] = ''
        options.properties['nifi.web.https.host'] ?= service.node.fqdn
        options.properties['nifi.web.https.port'] ?= '9760'
        options.properties['nifi.security.keystore'] ?= options.keystore.target
        options.properties['nifi.security.keystoreType'] ?= 'JKS'
        options.properties['nifi.security.keystorePasswd'] ?= options.keystore.password
        options.properties['nifi.security.keyPasswd'] ?= 'nifi123'
        options.properties['nifi.security.truststore'] ?= options.truststore.target
        options.properties['nifi.security.truststoreType'] ?= 'JKS'
        options.properties['nifi.security.truststorePasswd'] ?= options.truststore.password
        options.properties['nifi.security.needClientAuth'] ?= 'true'
        # Valid Authorities include: ROLE_MONITOR,ROLE_DFM,ROLE_ADMIN,ROLE_PROVENANCE,ROLE_NIFI
        # role given to anonymous users
        options.properties['nifi.security.anonymous.authorities'] ?= '' # no role given to anonymous
        # secure inner connection and remote
        options.properties['nifi.remote.input.secure'] ?= 'true'
      else
        options.properties['nifi.web.http.host'] ?= service.node.fqdn
        options.properties['nifi.web.http.port'] ?= '9750'
        options.properties['nifi.web.https.host'] = ''
        options.properties['nifi.web.https.port'] = ''

## User Authentication

      options.properties['nifi.security.user.login.identity.provider'] ?= 'kerberos-provider'
      options.properties['nifi.login.identity.provider.configuration.file'] ?= "#{options.conf_dir}/login-identity-providers.xml"
      options.login_providers ?= {}
      switch options.properties['nifi.security.user.login.identity.provider']
        when 'ldap-provider'
          ldap_provider = options.login_providers.ldap_provider ?= {}
          ldap_provider['auth_strategy'] ?= 'SIMPLE'
          throw Error 'ldap_provider.auth_strategy must be "ANONYMOUS", "SIMPLE", or "START_TLS"' if ldap_provider['auth_strategy'] not in ['ANONYMOUS', 'SIMPLE', 'START_TLS']
          ldap_provider['tls_keystore'] ?= "#{options.properties['nifi.security.keystore']}"
          ldap_provider['tls_keystore_pwd'] ?= "#{options.properties['nifi.security.keystorePasswd']}"
          ldap_provider['tls_keystore_type'] ?= "#{options.properties['nifi.security.keystoreType']}"
          ldap_provider['tls_truststore'] ?= "#{options.properties['nifi.security.truststore']}"
          ldap_provider['tls_truststore_pwd'] ?= "#{options.properties['nifi.security.truststorePasswd']}"
          ldap_provider['tls_truststore_type'] ?= "#{options.properties['nifi.security.truststoreType']}"
          ldap_provider['tls_truststore_protocol'] ?= 'TLS'
          ldap_provider['tls_client_auth'] ?= 'NONE'
          ldap_provider['ref_strategy'] ?= 'FOLLOW'
          unless ldap_provider['manager_dn']?
            throw Error 'no openldap server configured' unless service.deps.openldap_server.length?
            ldap_provider['manager_dn'] ?= "#{service.deps.openldap_server[0].options.root_dn}"
            ldap_provider['manager_pwd'] ?= "#{service.deps.openldap_server[0].options.root_password}"
            ldap_provider['url'] ?= "#{service.deps.openldap_server[0].options.uri}:636"
            ldap_provider['usr_search_base'] ?= service.deps.openldap_server[0].options.users_dn
            ldap_provider['usr_search_filter'] ?= 'uid={0}'#'ou=groups,dc=ryba'
        when 'kerberos-provider'
          krb5_provider = options.login_providers.krb5_provider ?= {}
          krb5_provider['realm'] ?= options.krb5.realm
          options.properties['nifi.kerberos.service.principal'] ?= "HTTP/#{service.node.fqdn}@#{options.krb5.realm}"
          options.properties['nifi.kerberos.keytab.location'] ?= '/etc/security/keytabs/spnego.service.keytab'
          options.admin ?= {}
          options.admin.krb5_principal ?= "#{options.user.name}@#{options.krb5.realm}"
          options.admin.krb5_password ?= 'nifi123'
        else
          throw Error 'login provider is not supported'
      options.properties['nifi.security.identity.mapping.pattern.dn'] ?= '^CN=(.*?),(.*)$'
      options.properties['nifi.security.identity.mapping.value.dn'] ?= '$1'
      options.properties['nifi.security.identity.mapping.pattern.kerb'] ?= '^(.*?)@(.*?)$'
      options.properties['nifi.security.identity.mapping.value.kerb'] ?= '$1'

## User Authorization

      options.properties['nifi.authorizer.configuration.file'] ?= "#{options.conf_dir}/authorizers.xml"
      options.properties['nifi.security.user.authorizer'] ?= 'file-provider'
      options.authorizers ?= {}
      switch options.properties['nifi.security.user.authorizer']
        when 'file-provider'
          file_provider = options.authorizers.file_provider ?= {}
          file_provider['authorizations_file'] ?= "#{options.conf_dir}/authorizations.xml"
          file_provider['users_file'] ?= "#{options.conf_dir}/users.xml"
          file_provider['initial_admin_identity'] ?= options.user.name
          file_provider['nodes_identities'] ?= service.deps.nifi.map( (srv) -> srv.node.fqdn)
        else
          throw Error 'Authorizer is not supported'

## Cluster Management

      switch options.properties['nifi.state.management.provider.cluster']
        when 'zk-provider'
          throw Error 'No zookeeper quorum configured' unless zk_hosts.length
          # used for nifi to authenticate to kerberos sucurized zookeeper ensemble
          if service.deps.hadoop_core[0].options.core_site['hadoop.security.authentication'] is 'kerberos'
            options.krb5_principal ?=  "#{options.user.name}/#{service.node.fqdn}@#{options.krb5.realm}"
            options.krb5_keytab ?=  '/etc/security/keytabs/nifi.service.keytab'
        else
          throw Error 'No other cluster state provider is supported for now'

## Java Opts
      
      options.java_home ?= service.deps.java.options.java_home if service.deps.java?
      options.java_opts ?= [
        '-Dorg.apache.jasper.compiler.disablejsr199=true'
        '-Xms512m'
        '-Xmx512m'
        '-Djava.net.preferIPv4Stack=true'
        '-Dsun.net.http.allowRestrictedHeaders=true'
        '-Djava.protocol.handler.pkgs=sun.net.www.protocol'
        '-XX:+UseG1GC'
        '-Djava.awt.headless=true'
      ]
      options.java_opts.push "-Djava.security.auth.login.config=#{options.conf_dir}/nifi-zookeeper.jaas"

## Log4J

      options.log4j = mixme service.deps.log4j?.options, options.log4j
      options.log4j.properties ?= {}

      options.logback ?= {}
      options.logback.version ?= "1.1.7"
      options.logback.socketappender ?= {}
      options.logback.socketappender.version ?= "4.8"
      options.logback.socketappender.source ?= "http://central.maven.org/maven2/net/logstash/logback/logstash-logback-encoder/#{options.logback.socketappender.version}/logstash-logback-encoder-#{options.logback.socketappender.version}.jar"
      options.logback.core ?= {}
      options.logback.core.source ?= "http://central.maven.org/maven2/ch/qos/logback/logback-core/#{options.logback.version}/logback-core-#{options.logback.version}.jar"
      options.logback.classic ?= {}
      options.logback.classic.source ?= "http://central.maven.org/maven2/ch/qos/logback/logback-core/#{options.logback.version}/logback-classic-#{options.logback.version}.jar"
      options.logback.access ?= {}
      options.logback.access.source ?= "http://central.maven.org/maven2/ch/qos/logback/logback-core/#{options.logback.version}/logback-access-#{options.logback.version}.jar"

## Additional Libs

Set local path of additional libs (for custom processors) in this array.

      options.custom_libs_dir ?= []

## Data Directories Layout

      props = Object.keys(options.properties).filter (prop) ->
       prop.indexOf('nifi.content.repository.directory') > -1 or prop.indexOf('nifi.provenance.repository.directory') > -1
      options.data_dirs ?= []
      options.data_dirs.push options.properties[prop] for prop in props

## Wait

      protocol = if options.properties['nifi.cluster.protocol.is.secure'] is 'true' then 'https' else 'http'
      options.wait ?= {}
      options.wait.webui = for srv in service.deps.nifi
        host: srv.node.fqdn
        port: srv.options.properties["nifi.web.#{protocol}.port"] or options.properties["nifi.web.#{protocol}.port"] or '9760'

## Dependencies

    mixme = require 'mixme'

[nifi-properties]:https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#cluster-node-properties
