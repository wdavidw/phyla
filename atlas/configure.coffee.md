
# Atlas Configuration

Apache Atlas Metadata Server Configuration.

Internally Atlas embeds a [Titan][titan] graph database. Titan for working, needs
a solr cluster for storing indexes and an HBase cluster as the data storage.

Atlas needs also kafka as a bus to broadcats message betwwen the different components
(e.g. Hive, Ranger).

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/atlas', ['ryba', 'atlas'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        zookeeper_server: key: ['ryba', 'zookeeper']
        hadoop_core: key: ['ryba']
        hbase_master: key: ['ryba', 'hbase', 'master']
        kafka_broker: key: ['ryba', 'kafka', 'broker']
        ranger_tagsync: key: ['ryba', 'ranger', 'tagsync'] # migration: wdavidw 171006, service does not exists
        atlas: key: ['ryba', 'atlas']
      options = @config.ryba.atlas = service.options
      
      # Servers onfiguration
      sc_ctxs = @contexts 'ryba/solr/cloud'
      scd_ctxs = @contexts 'ryba/solr/cloud_docker'
      options = @config.ryba.atlas ?= {}

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'atlas'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'atlas'
      options.user.system ?= true
      options.user.comment ?= 'Atlas User'
      options.user.home ?= '/var/lib/atlas'
      options.user.groups ?= ['hadoop']
      options.user.gid = options.group.name

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]


## Environment

      options.conf_dir ?= '/etc/atlas/conf'
      options.log_dir ?= '/var/log/atlas'
      options.pid_dir ?= '/var/run/atlas'
      options.server_opts ?= ''
      options.server_heap ?= ''
      options.cluster_name ?= 'atlas-on-ryba-cluster'
      options.ranger_solr_plugin ?= @contexts('ryba/ranger/admin').length isnt -1
      options.metadata_opts ?= {}
      # options.metadata_opts['java.security.auth.login.config'] ?= "#{options.conf_dir}/atlas-server.jaas"
      options.atlas_opts ?= {}
      options.atlas_opts['java.security.auth.login.config'] ?= "#{options.conf_dir}/atlas-server.jaas"
      options.atlas_opts['log4j.configuration'] ?= 'atlas-log4j.xml'
      # Layout
      options.env ?= {}
      options.env['ATLAS_PID_DIR'] ?= "#{options.pid_dir}"
      options.env['ATLAS_LOG_DIR'] ?= "#{options.log_dir}"
      options.env['ATLAS_HOME_DIR'] ?= '/usr/hdp/current/atlas-server'
      options.env['ATLAS_DATA_DIR'] ?= "#{options.user.home}/data"
      options.env['ATLAS_EXPANDED_WEBAPP_DIR'] ?= "#{options.user.home}/server/webapp"
      options.env['HBASE_CONF_DIR'] ?= "#{options.conf_dir}/hbase"
      # Java
      options.min_heap ?= '512m'
      options.max_heap ?= '512m'


## Configuration

      options.application ?= {}
      options.application.properties ?= {}
      options.application.properties['atlas.server.bind.address'] ?= "#{service.use.node}" # migration: wdavidw, really, bindinng a server to a FQDN and not an IP or 0.0.0.0 ? let's leave a comment to explain it.
      options.application.properties['atlas.taxonomy.default.name'] ?= 'Catalog'
      options.application.properties['atlas.rest-csrf.enabled'] ?= 'true'
      options.application.properties['atlas.rest-csrf.browser-useragents-regex'] ?= '^Mozilla.*,^Opera.*,^Chrome.*'
      options.application.properties['atlas.rest-csrf.methods-to-ignore'] ?= 'GET,OPTIONS,HEAD,TRACE'
      options.application.properties['atlas.rest-csrf.custom-header'] ?= 'X-XSRF-HEADER'
      options.application.properties['atlas.feature.taxonomy.enable'] ?= 'true'

## Kerberos
Atlas, when communicating with other components (Solr,HBase,Kafka) needs to authenticate
itself as a client. It uses the JAAS mechanism.
The JAAS informations can be set via a jaas file or the properties can be set directly
from atlas-application.properties file.

      options.application.properties['atlas.authentication.method'] ?= @config.ryba.security
      options.application.properties['atlas.authentication.principal'] ?= "#{atlas.user.name}/_HOST@#{options.krb5.realm}"
      options.application.properties['atlas.authentication.keytab'] ?= '/etc/security/keytabs/atlas.service.keytab'
      options.application.properties['atlas.http.authentication.enabled'] ?= true
      options.application.properties['atlas.http.authentication.type'] ?=  atlas.application.properties['atlas.authentication.method']
      options.application.properties['atlas.http.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      options.application.properties['atlas.http.authentication.kerberos.keytab'] ?= '/etc/security/keytabs/spnego.service.keytab'
      # options.application.properties['atlas.jaas.Client.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
      # options.application.properties['atlas.jaas.Client.loginModuleControlFlag'] ?= 'required'
      # options.application.properties['atlas.jaas.Client.option.useKeyTab'] ?= 'true'
      # options.application.properties['atlas.jaas.Client.option.storeKey'] ?= 'true'
      # options.application.properties['atlas.jaas.Client.option.useTicketCache'] ?= 'false'
      # options.application.properties['atlas.jaas.Client.option.doNotPrompt'] ?= 'false'
      # options.application.properties['atlas.jaas.Client.option.keyTab'] ?= atlas.application.properties['atlas.authentication.keytab']
      # options.application.properties['atlas.jaas.Client.option.principal'] ?= atlas.application.properties['atlas.authentication.principal'].replace '_HOST', service.use.fqdn

## Kerberos Atlas Admin User

      if atlas.application.properties['atlas.authentication.method'] is 'kerberos'
        match_princ = /^(.+?)[@\/]/.exec options.application.properties['atlas.authentication.principal']
        throw Error 'Invalid Atlas  principal' unless match_princ?
        options.admin_principal ?= "#{options.user.name}@#{options.krb5.realm}"
        options.admin_password ?= 'atlas123'
        match_admin = /^(.+?)[@\/]/.exec options.admin_principal
        throw Error "Principal Name does not match admin user name" unless match_admin[1] is match_princ[1]

## Authentication Method
Several authentication method can be used (Kerberos, ldap, file).
More that one method can be enabled. An admin user should exist for managinf other.

Note: In HDP 2.5.x LDAP option in Atlas can't pass full DN parameters which resultat
in impossibility to log in using LDAP: Logs can look like `[LDAP: error code 32 - No Such Object]`
The solution is to escape all commas in the DNs used for LDAP configuration.
Forexample, `atlas.authentication.method.ldap.userDNpattern`=`cn=users\,cn=accounts\,dc=field\,dc=hortonworks\,dc=com`.

      options.application.properties['atlas.authentication.method.ldap'] ?= 'false' #No custom configs
      options.application.properties['atlas.authentication.method.kerberos'] ?= "#{@config.ryba.security is 'kerberos'}"
      options.application.properties['atlas.authentication.method.file'] ?= 'true'
      # Configure kerberos authentication
      if options.application.properties['atlas.authentication.method.kerberos'] is 'true'
        options.application.properties['atlas.authentication.method.kerberos.principal'] ?= options.application.properties['atlas.http.authentication.kerberos.principal']
        options.application.properties['atlas.authentication.method.kerberos.keytab'] ?= options.application.properties['atlas.http.authentication.kerberos.keytab']
        # options.application.properties['atlas.authentication.method.kerberos.name.rules'] ?= core_site['hadoop.security.auth_to_local']
      # Configure file authentication
      if options.application.properties['atlas.authentication.method.file'] is 'true'
        options.application.properties['atlas.authentication.method.file.filename'] ?= "#{options.conf_dir}/users-credentials.properties"
        options.admin_user ?= 'admin'
        options.admin_password ?= 'admin123'
        options.user_creds ?= {}
        options.user_creds["#{options.admin_user}"] ?=
          name: "#{options.admin_user}"
          password: "#{options.admin_password}"
          group: "ADMIN"

## Authorization
Atlas accepts only simple (file) or Ranger based [authorization](http://atlas.incubator.apache.org/Authentication-Authorization.html).

      options.application.properties['atlas.authorizer.impl'] ?= if service.use.ranger_tagsync.length > 0 then 'ranger' else 'simple'
      if options.application.properties['atlas.authorizer.impl'] is 'simple'
        options.application.properties['atlas.auth.policy.file'] ?= "#{options.conf_dir}/policy-store.txt"
        options.admin_users ?= []
        options.admin_users.push options.admin_users if options.admin_user? and options.admin_users.indexOf(options.admin_user) isnt -1

## Automatic Check on start up
Atlas server does take care of parallel executions of the setup steps.

      options.application.properties['atlas.server.run.setup.on.start'] ?= 'false'

## SSL
Atlas SSL Encryption can be enabled by configuring following properties.

      options.serverkey_password ?= 'ryba123'
      options.keystore_password ?= 'ryba123'
      options.truststore_password ?= 'ryba123'
      options.application.properties['atlas.enableTLS'] ?= 'true'
      options.application.properties['keystore.file'] ?= "#{options.conf_dir}/keystore"
      options.application.properties['truststore.file'] ?= "#{options.conf_dir}/truststore"
      options.application.properties['client.auth.enabled'] ?= "false"
      options.application.properties['atlas.server.http.port'] ?= '21000'
      options.application.properties['atlas.server.https.port'] ?= '21443'
      # http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/CommandsManual.html#credential
      # for now ryba only support creating the jceks file on the local atlas server.
      # but you can manually (if using the same truststore and keystore on each server)
      # uploading the provider generate into hdfs
      options.application.properties['cert.stores.credential.provider.path'] ?= "jceks://file#{options.conf_dir}/credential.jceks"
      protocol = if options.application.properties['atlas.enableTLS'] is 'true' then 'https' else 'http'
      port = options.application.properties["atlas.server.#{protocol}.port"]
      options.application.properties['atlas.app.port'] ?= port

## REST Address

      rest_address = "#{protocol}://#{service.use.fqdn}:#{port}"
      options.application.properties['atlas.rest.address'] ?= rest_address
      options.application.urls ?= "#{rest_address}"

## High Availability

From 0.7.0 (hdp 2.5.3.0-37) Atlas Metada server support high availability in an active/passive fashion.
Failover is automatically based on Zookeeper leader election.

The Quorum property is mandatory even if the HA is not enabled or the following error is thrown
Error injecting constructor, java.lang.NullPointerException: connectionString cannot be null

      zookeeper_quorum = for srv in service.use.zookeeper_server
        continue unless srv.options.config['peerType'] is 'participant'
        "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"
      options.application.properties['atlas.server.ha.zookeeper.connect'] ?= zookeeper_quorum.join ','
      if service.use.atlas.length > 1
        options.application.properties['atlas.server.ha.zookeeper.acl'] ?= "sasl:#{options.user.name}@#{options.krb5.realm}"
        options.application.properties['atlas.server.ha.zookeeper.auth'] ?= "sasl:#{options.user.name}@#{options.krb5.realm}"
        options.application.properties['atlas.server.ha.zookeeper.zkroot'] ?= '/apache_atlas'

## High Availability with Automatic Failover

Using Official atlas [documentation](http://atlas.incubator.apache.org/HighAvailability.html) 
for HA configuration, (not available on HDP website).
Ryba does configure atlas server with the same port for every instance.

      options.application.properties['atlas.server.ha.enabled'] ?= if service.use.atlas.length > 1 then 'true' else 'false'
      options.application.properties['atlas.server.ids'] ?= service.nodes.map( (node) -> node.hostname ).join ','
      for node in service.nodes
        options.application.properties["atlas.server.address.#{node.hostname}"] ?= "#{node.fqdn}:#{port}"

##  Apache Kafka Notification

Required for Ranger integration or anytime there is a consumer of entity change notifications.

      if service.use.kafka_broker?
        # Includes the required Atlas directories to the hadoop-env configuration export
        @config.ryba.hadoop_classpath = add_prop  @config.ryba.hadoop_classpath, "#{options.conf_dir}:/usr/hdp/current/atlas-server/hook/hive", ':'
        # Configure Kafka Broker properties
        options.application.properties['atlas.notification.embedded'] ?= 'false'
        options.application.properties['atlas.kafka.sasl.kerberos.service.name'] ?= 'kafka'
        options.application.properties['atlas.kafka.data'] ?= "#{options.user.home}/data/kafka" # {options.user.home}/keystore"
        options.application.properties['atlas.kafka.zookeeper.connect'] ?= "#{service.use.kafka_broker[0].options.config['zookeeper.connect']}"
        options.application.properties['atlas.kafka.zookeeper.session.timeout.ms'] ?= '1000'
        options.application.properties['atlas.kafka.zookeeper.sync.time.ms'] ?= '20'
        options.application.properties['atlas.kafka.auto.commit.interval.ms'] ?= '1000'
        options.application.properties['atlas.kafka.hook.group.id'] ?= 'atlas'
        options.application.properties['atlas.kafka.entities.group.id'] ?= 'atlas'
        options.application.properties['atlas.kafka.auto.commit.enable'] ?= 'false'
        options.application.properties['atlas.notification.create.topics'] ?= 'false'
        options.application.properties['atlas.notification.replicas'] ?= "#{service.use.kafka_broker.length}"
        options.application.properties['atlas.notification.log.failed.messages'] ?= '500'
        options.application.properties['atlas.notification.consumer.retry.interval'] ?= '10'
        options.application.properties['atlas.notification.hook.retry.interval'] ?= '1000'
        options.application.properties['atlas.kafka.auto.offset.reset'] ?= 'smallest'
        options.application.properties['atlas.notification.topics'] ?= 'ATLAS_HOOK,ATLAS_ENTITIES'
        # Kafka Jaas client configuration
        options.application.properties['atlas.jaas.KafkaClient.loginModuleControlFlag'] ?= 'required'
        options.application.properties['atlas.jaas.KafkaClient.loginModuleName'] ?= 'com.sun.security.auth.module.Krb5LoginModule'
        options.application.properties['atlas.jaas.KafkaClient.option.keyTab'] ?= '/etc/security/keytabs/atlas.service.keytab'
        options.application.properties['atlas.jaas.KafkaClient.option.principal'] ?= "#{options.user.name}/_HOST@#{options.krb5.realm}"
        options.application.properties['atlas.jaas.KafkaClient.option.serviceName'] ?= 'kafka'
        options.application.properties['atlas.jaas.KafkaClient.option.storeKey'] ?= 'true'
        options.application.properties['atlas.jaas.KafkaClient.option.useKeyTab'] ?= 'true'
        # Choose kafka broker channel by preference order
        chanels = []
        chanels.push 'SASL_SSL' if @config.ryba.security is 'kerberos' and options.application.properties['atlas.enableTLS'] is 'true'
        chanels.push 'SASL_PLAINTEXT' if @config.ryba.security is 'kerberos'
        chanels.push 'SSL' if options.application.properties['atlas.enableTLS'] is 'true'
        chanels.push 'PLAINTEXT'
        # Recording choosen protocol
        options.application.properties['atlas.kafka.security.protocol'] ?= chanels[0]
        options.application.kafka_chanel = options.application.properties['atlas.kafka.security.protocol']
        # `kafka.broker.protocols` are available client protocols for communicating with broker
        if options.application.kafka_chanel in service.use.kafka_broker[0].options.protocols
          brokers = service.use.kafka_broker.map( (srv) =>
            "#{srv.node.fqdl}:#{srv.options.ports[options.application.kafka_chanel]}"
          ).join ','
          # construcut the bootstrap listeners string base on channel
          # i.e.: SASL_SSL://master1.ryba:9096,master2.ryba:9096,master3.ryba:9096 for example
          options.application.properties['atlas.kafka.bootstrap.servers'] ?= "#{options.application.kafka_chanel}://#{brokers}"
          if options.application.kafka_chanel in ['SSL','SASL_SSL']
            options.application.properties['atlas.kafka.ssl.truststore.location'] ?= @config.ryba.kafka.consumer.config['']
            options.application.properties['atlas.kafka.ssl.truststore.password'] ?= @config.ryba.kafka.consumer.config['ssl.truststore.password']
        else
          throw Error "Atlas Selected Kafka Protocol #{options.application.kafka_chanel} is not allowed by Kafka Brokers configuration"

## Ranger Tag Base Policies configuration

      for srv in service.use.ranger_tagsync
        srv.options.atlas_properties ?= {}
        for prop in [
          'atlas.notification.embedded'
          'atlas.kafka.data'
          'atlas.kafka.zookeeper.connect'
          'atlas.kafka.bootstrap.servers'
          'atlas.kafka.security.protocol'
          'atlas.kafka.zookeeper.session.timeout.ms'
          'atlas.kafka.zookeeper.sync.time.ms'
          'atlas.kafka.auto.commit.interval.ms'
          'atlas.kafka.hook.group.id'
        ] then srv.options.atlas_properties[prop] ?= options.application.properties[prop]

## Atlas Ranger User

      options.ranger_user ?=
        "name": 'atlas'
        "firstName": 'atlas'
        "lastName": 'hadoop'
        "emailAddress": 'atlas@hadoop.ryba'
        'userSource': 1
        'userRoleList': ['ROLE_USER']
        'groups': []
        'status': 1

## Titan MetaData Database

Atlas uses Titan as its its metadata storage.
The Titan database can be configured with HBase as its storage database, and
Solr for its indexing backend

### Storage Backend

      options.storage_engine ?= 'hbase'
      if options.storage_engine is 'hbase'
        if service.use.hbase_master
          options.application.properties['atlas.graph.storage.backend'] ?= 'hbase'
          options.application.properties['atlas.graph.storage.hostname'] ?= service.use.hbase_master[0].options.hbase_site['hbase.zookeeper.quorum']
          options.application.properties['zookeeper.znode.parent'] ?= service.use.hbase_master[0].options.hbase_site['zookeeper.znode.parent']
          options.application.namespace ?= 'atlas'
          options.application.properties['atlas.graph.storage.hbase.table'] ?= "#{options.application.namespace}:atlas_titan"
          options.application.properties['atlas.audit.hbase.tablename'] ?= "#{options.application.namespace}:atlas_entity_audit"
        else
          throw Error 'No HBase cluster is configured'

### Indexing Engine
Atlas support only solr on cloud mode. Atlas' Ryba installation support solrcoud 
in or out of docker.

      options.indexing_engine ?= 'solr'
      if options.indexing_engine is 'solr'
        options.solr_type ?= 'cloud_docker'
        solr_ctx = {}
        options.application.properties['atlas.solr.kerberos.enable'] ?= if service.use.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos' then 'true' else 'false'
        switch options.solr_type
          when 'cloud'
            throw Error 'No Solr Cloud Server configured' unless sc_ctxs.length > 0
            options.solr_admin_user ?= 'solr'
            options.solr_admin_password ?= 'SolrRocks' #Default
            options.cluster_config ?=
              atlas_collection_dir: "#{sc_ctxs[0].config.ryba.solr.cloud.conf_dir}/clusters/atlas_solr"
              hosts: sc_ctxs.map( (ctx)-> ctx.config.host)
            # register collection creation just once
            if @contexts('ryba/atlas').map( (ctx) -> ctx.config.host )[0] is service.use.fqdn
              sc_ctxs[0]
              .after
                type: ['service','start']
                name: 'solr'
              , -> @call 'ryba/atlas/solr_layout'
          when 'cloud_docker'
            throw Error 'No Solr Cloud Server configured' unless scd_ctxs.length > 0
            cluster_name = options.solr_cluster_name ?= 'atlas_infra'
            options.solr_admin_user ?= 'solr'
            options.solr_admin_password ?= 'SolrRocks' #Default
            options.solr_users ?= [
              name: 'ranger'
              secret: 'ranger123'
            ]
            {solr} = @config.ryba
            solr.cloud_docker ?= {}
            solr.cloud_docker.clusters ?= {}
            #Search for a cloud_docker cluster find in solr.cloud_docker.clusters
            for key, solr_ctx of scd_ctxs
              solr = solr_ctx.config.ryba.solr ?= {}
              #By default Ryba search for a solr cloud cluster named ryba_ranger_cluster in config
              # Configures one cluster if not in config
              solr_ctx.config.ryba.solr.cloud_docker.clusters ?= {}
              cluster_config  = options.solr_cluster_config ?= {}
              cluster_config.volumes ?= []
              cluster_config.atlas_collection_dir = "#{solr.cloud_docker.conf_dir}/clusters/#{cluster_name}/atlas_solr"
              cluster_config.volumes.push "#{cluster_config.atlas_collection_dir}:/atlas_solr" if cluster_config.volumes.indexOf("#{solr.cloud_docker.conf_dir}/clusters/#{cluster_name}/atlas_solr:/atlas_solr") is -1
              cluster_config['containers'] ?= scd_ctxs.length
              cluster_config['master'] ?= scd_ctxs[0].config.host
              cluster_config['heap_size'] ?= '256m'
              cluster_config['port'] ?= 8985
              cluster_config.zk_opts ?= {}
              cluster_config.rangerEnabled ?= options.ranger_solr_plugin
              cluster_config['hosts'] ?= scd_ctxs.map (ctx) -> ctx.config.host
              clusterized_config = configure_solr_cluster solr_ctx , cluster_name, cluster_config
              solr_ctx.config.ryba.solr.cloud_docker.clusters[cluster_name] = Object.assign {},clusterized_config
              if service.node.fqdn is service.use.atlas[0].nonde.fqdn
                solr_ctx
                .after
                  type: ['file','yaml']
                  target: "#{solr.cloud_docker.conf_dir}/clusters/#{cluster_name}/docker-compose.yml"
                , (_, cb) ->
                    dir = "#{cluster_config.atlas_collection_dir}"
                    @file.download
                      source: "#{__dirname}/resources/solr/lang/stopwords_en.txt"
                      target: "#{dir}/lang/stopwords_en.txt"
                    @file.download
                      source: "#{__dirname}/resources/solr/currency.xml"
                      target: "#{dir}/currency.xml"
                    @file.download
                      source: "#{__dirname}/resources/solr/protwords.txt"
                      target: "#{dir}/protwords.txt"
                    @file.download
                      source: "#{__dirname}/resources/solr/schema.xml"
                      target: "#{dir}/schema.xml"
                    @file.download
                      source: "#{__dirname}/resources/solr/solrconfig.xml"
                      target: "#{dir}/solrconfig.xml"
                    @file.download
                      source: "#{__dirname}/resources/solr/stopwords.txt"
                      target: "#{dir}/stopwords.txt"
                    @file.download
                      source: "#{__dirname}/resources/solr/synonyms.txt"
                      target: "#{dir}/synonyms.txt"
                    @then cb
                solr_ctx
                .after
                  type: ['docker','compose','up']
                  target: "#{solr.cloud_docker.conf_dir}/clusters/#{cluster_name}/docker-compose.yml"
                , -> @call 'ryba/atlas/solr_layout', cluster_config: options.cluster_config
            options.cluster_config = scd_ctxs[0].config.ryba.solr.cloud_docker.clusters[cluster_name]
            urls = cluster_config.zk_connect.split(',').map( (host) -> "#{host}/#{cluster_config.zk_node}").join(',')
            options.application.properties['atlas.graph.index.search.solr.zookeeper-url'] ?= "#{urls}"
            options.application.properties['atlas.graph.index.search.solr.mode'] ?= 'cloud'
            options.application.properties['atlas.graph.index.search.backend'] ?= 'solr5'

    add_prop = (value, add, separator) ->
      throw Error 'No separator provided' unless separator?
      value ?= ''
      return add if value.length is 0
      return if value.indexOf(add) is -1 then "#{value}#{separator}#{add}" else value

## Dependencies

    configure_solr_cluster = require '../solr/cloud_docker/clusterize'
    migration = require 'masson/lib/migration'

[titan]:(http://titan.thinkaurelius.com)
