
# Configure Solr Cloud cluster on docker

This module configures the servers to be able to run different solrCloud cluster in 
docker containers. The configuration is made in two steps:
- The first is to create host level configuration as we would do without docker
The host level configuration will be shared by the different containers running 
on the same host.
- The second step consists to configure each SolrCloud cluster  on the container level
by looping through each on of it and configuring the different properties.
These properties are unique to each container, depending on the cluster/host it 
belongs to.
For now we supports only (at the cluster level) only one container by host.


Solr accepts differents sources:
 - HDP to use HDP lucidworks repos

```cson
ryba:
  solr:
    source: 'HDP'
    jre_home: '/usr/java/jdk1.8.0_91/jre'
    env:
      'SOLR_JAVA_HOME': '/usr/java/jdk1.8.0_91'
```
 - apache community edition to use the official release:   
 in this case you can choose the version

```cson
ryba:
  solr:
    jre_home: '/usr/java/jdk1.8.0_91/jre'
    env:
      'SOLR_JAVA_HOME': '/usr/java/jdk1.8.0_91'
    version: '6.0.0'
    source: 'http://mirrors.ircam.fr/pub/apache/lucene/solr/6.0.0/solr-6.0.0.tgz'
```

    module.exports =  (service) ->
      service = migration.call @, service, 'ryba/solr/cloud_docker', ['ryba', 'solr', 'cloud_docker'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        docker: key: ['docker']
        krb5_client: key: ['krb5_client']
        ssl: key: ['ssl']
        java: key: ['java']
        zookeeper_server: key: ['ryba', 'zookeeper']
        hadoop_core: key: ['ryba']
        # hdfs_client: key: ['ryba', 'hdfs_client']
        solr_cloud_docker: key: ['ryba','solr','cloud_docker']
        swarm_agent: key: ['ryba', 'swarm', 'agent']
      @config.ryba ?= {}
      @config.ryba.solr ?= {}
      options = @config.ryba.solr.cloud_docker = service.options

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'solr'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'solr'
      options.user.home ?= "/var/#{options.user.name}/data"
      options.user.system ?= true
      options.user.comment ?= 'Solr User'
      options.user.groups ?= 'hadoop'
      options.user.gid ?= options.group.name
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= true
      options.hadoop_group = merge {}, service.use.hadoop_core.options.hadoop_group, options.hadoop_group


## Environment

      options ?= {}
      options.version ?= '6.6.1'
      options.source ?= "http://apache.mirrors.ovh.net/ftp.apache.org/dist/lucene/solr/#{options.version}/solr-#{options.version}.tgz"
      options.root_dir ?= '/usr'
      options.install_dir ?= "#{options.root_dir}/solr-cloud/#{options.version}"
      options.latest_dir ?= "#{options.root_dir}/solr-cloud/current"
      options.latest_dir = '/opt/lucidworks-hdpsearch/solr' if options.source is 'HDP'
      options.pid_dir ?= '/var/run/solr'
      options.log_dir ?= '/var/log/solr'
      options.conf_dir ?= '/etc/solr-cloud-docker/conf'
      options.build ?= {}
      options.build.dir ?= "#{options.cache_dir}/solr"
      options.build.image ?= "ryba/solr"
      options.build.tar ?= "solr_image.tar"
      options.build.source ?= "#{options.build.dir}/#{options.build.tar}"
      options.docker_compose_version ?= '2'

## Docker Daemon

      options.docker ?= {}
      options.docker[opt] ?= service.use.docker.options[opt] for opt in [
        'host'
        'default_port'
        'tlscacert'
        'tlscert'
        'tlskey'
        'tlsverify'
        'conf_dir'
      ]

## Configuration

      # Layout
      options.log_dir ?= '/var/log/solr'
      options.pid_dir ?= '/var/run/solr'
      zk_hosts = service.use.zookeeper_server.filter( (srv) -> srv.options.config['peerType'] is 'participant')
      options.zk_connect = zk_hosts.map( (srv) -> "#{srv.node.fqdn}:#{srv.options.config['clientPort']}").join ','
      options.zkhosts = "#{options.zk_connect}/solr"
      options.zk_node = "/solr"
      options.dir_factory ?= "${solr.directoryFactory:solr.NRTCachingDirectoryFactory}"
      options.lock_type = 'native'
      # Misc
      options.clean_logs ?= false
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      options.fqdn ?= service.node.fqdn
      options.jaas_path ?= "#{options.conf_dir}/solr-server.jaas"

## Version Fix
Before 6.0 version, solr.xml'<solrCloud> section has a mistake:
The property `zkCredentialsProvider` was named `zkCredientialsProvider`

      options.conf_source = if (options.version.split('.')[0] < 6) or (options.source is 'HDP')
      then "#{__dirname}/../resources/cloud/solr_5.xml.j2"
      else "#{__dirname}/../resources/cloud/solr_6.xml.j2"

## Security

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]
      options.security ?= {}
      options.security["authentication"] ?= {}
      options.security["authentication"]['class'] ?= if service.use.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
      then 'org.apache.solr.security.KerberosPlugin'
      else 'solr.BasicAuthPlugin'
      if service.use.hadoop_core.options.core_site['hadoop.security.authentication'] is 'kerberos'
        # Kerberos
        options.admin_principal ?= "#{options.user.name}@#{options.krb5.realm}"
        throw Error 'Missing Keberos Admin Principal Password (solr.cloud_docker.admin_password)' unless options.admin_password?
        options.admin_principal ?= solr.admin_principal
        options.admin_password ?= solr.admin_password
        options.principal ?= "#{options.user.name}/#{@config.host}@#{options.krb5.realm}"
        options.keytab ?= '/etc/security/keytabs/solr.service.keytab'
        options.spnego ?= {}
        options.spnego.principal ?= "HTTP/#{@config.host}@#{options.krb5.realm}"
        options.spnego.keytab ?= '/etc/security/keytabs/spnego.service.keytab'
        options.auth_opts ?= {}
        options.auth_opts['solr.kerberos.cookie.domain'] ?= "#{@config.host}"
        options.auth_opts['java.security.auth.login.config'] ?= "#{options.conf_dir}/solr-server.jaas"
        options.auth_opts['solr.kerberos.principal'] ?= options.spnego.principal
        options.auth_opts['solr.kerberos.keytab'] ?= options.spnego.keytab
        options.auth_opts['solr.kerberos.name.rules'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
        # Authentication

## SSL

      options.port ?= 8893
      options.ssl = merge {}, service.use.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.use.ssl
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

## Docker Daemon config

      if service.use.swarm_agent?
        options.swarm_conf ?=
          host: "tcp://#{service.use.swarm_agent.options.advertise_host}:#{service.use.swarm_agent.options.advertise_port ? 2376}"
          tlsverify:" "
          tlscacert: "/etc/docker/certs.d/ca.pem"
          tlscert: "/etc/docker/certs.d/cert.pem"
          tlskey: "/etc/docker/certs.d/key.pem"
      else
        options.swarm_conf = null
      options.docker ?= {}
      options.docker[opt] ?= service.use.docker.options[opt] for opt in [
        'host'
        'default_port'
        'tlscacert'
        'tlscert'
        'tlskey'
        'tlsverify'
        'conf_dir'
      ]
      options.fqdn ?= service.node.fqdn

## Environment

      options.env ?= {}
      options.env['SOLR_JAVA_HOME'] ?= service.use.java.options.java_home
      options.env['SOLR_HOST'] ?= service.node.fqdn
      options.env['SOLR_PID_DIR'] ?= options.pid_dir
      options.env['SOLR_HEAP'] ?= "512m"
      # options.env['SOLR_AUTH_TYPE'] ?= service.use.hadoop_core.options.core_site['hadoop.security.authentication']
      options.env['ENABLE_REMOTE_JMX_OPTS'] ?= 'false'
      if options.ssl.enabled
        options.env['SOLR_SSL_KEY_STORE'] ?= options.keystore.target
        options.env['SOLR_SSL_KEY_STORE_PASSWORD'] ?= options.keystore.password
        options.env['SOLR_SSL_TRUST_STORE'] ?= options.truststore.target
        options.env['SOLR_SSL_TRUST_STORE_PASSWORD'] ?= options.truststore.password
        options.env['SOLR_SSL_NEED_CLIENT_AUTH'] ?= 'false'#require client authentication  by using cert

      # configure all cluster present in conf/config.coffee solr configuration
      options.hosts = service.use.solr_cloud_docker.map (srv) -> srv.node.fqdn
      #need
      # - options (to have global solr/cloud_docker configuration)
      # - cluster_name ( to name configs respectively to clusters)
      # - cluster_config (to override default values like master nodes)
      options.clusters ?= {}
      for cluster_name, cluster_config of options.clusters
        cluster = configure_solr_cluster options, cluster_name, cluster_config
      #https://community.hortonworks.com/articles/15159/securing-solr-collections-with-ranger-kerberos.html

# Wait

      options.wait_krb5_client = service.use.krb5_client.options.wait
      options.wait_zookeeper_server = service.use.zookeeper_server[0].options.wait

## Dependencies

    configure_solr_cluster = require './clusterize'
    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
