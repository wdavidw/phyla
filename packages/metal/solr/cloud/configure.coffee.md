

## Configure
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

    module.exports = (service) ->
      options = service.options

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
      options.hadoop_group ?= service.deps.hadoop_core[0].options.hadoop_group

## Environment

      options.version ?= '6.6.1'
      options.host ?= service.node.fqdn # need for rendering xml
      options.source ?= "http://apache.mirrors.ovh.net/ftp.apache.org/dist/lucene/solr/#{options.version}/solr-#{options.version}.tgz"
      options.root_dir ?= '/usr'
      options.install_dir ?= "#{options.root_dir}/solr-cloud/#{options.version}"
      options.latest_dir ?= "#{options.root_dir}/solr-cloud/current"
      options.latest_dir = '/opt/lucidworks-hdpsearch/solr' if options.source is 'HDP'
      options.pid_dir ?= '/var/run/solr'
      options.log_dir ?= '/var/log/solr'
      options.conf_dir ?= '/etc/solr-cloud/conf'


## Configuration
Ryba installs solrcloud with a single instance (one core).
However, once installed, the user can start easily several instances for 
differents cores ( and so with different ports).

      # Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.shards ?= service.deps.solr_cloud.length
      options.clean_logs ?= false
      # Layout
      options.port ?= 8983
      options.env ?= {}
      zk_hosts = service.deps.zookeeper_server.filter( (srv) -> srv.options.config['peerType'] is 'participant')
      options.zk_connect = zk_hosts.map( (srv) -> "#{srv.node.fqdn}:#{srv.options.config['clientPort']}").join ','
      options.zk_node ?= 'solr'
      options.zkhosts = "#{options.zk_connect}/#{options.zk_node}"
      options.dir_factory ?= "${solr.directoryFactory:solr.NRTCachingDirectoryFactory}"
      options.lock_type = 'native'
      options.jaas_path ?= "#{options.conf_dir}/solr-server.jaas"

## Fix Conf
Before 6.0 version, solr.xml'<solrCloud> section has a mistake:
The property `zkCredentialsProvider` is named `zkCredientialsProvider`

      options.conf_source = if (options.version.split('.')[0] < 6) or (options.source is 'HDP')
      then "#{__dirname}/../resources/cloud/solr_5.xml.j2"
      else "#{__dirname}/../resources/cloud/solr_6.xml.j2"

## Security

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      options.security ?= {}
      options.security["authentication"] ?= {}
      options.security["authentication"]['class'] ?= if  service.deps.hadoop_core[0].options.core_site['hadoop.security.authentication'] is 'kerberos'
      then 'org.apache.solr.security.KerberosPlugin'
      else 'solr.BasicAuthPlugin'
      if service.deps.hadoop_core[0].options.core_site['hadoop.security.authentication'] is 'kerberos'
        options.admin_principal ?= "#{options.user.name}@#{options.krb5.realm}"
        options.admin_password ?= 'solr123'
        options.admin_principal ?= options.admin_principal
        options.admin_password ?= options.admin_password
        options.principal ?= "#{options.user.name}/#{service.node.fqdn}@#{options.krb5.realm}"
        options.keytab ?= '/etc/security/keytabs/solr.service.keytab'
        options.spnego ?= {}
        options.spnego.principal ?= "HTTP/#{service.node.fqdn}@#{options.krb5.realm}"
        options.spnego.keytab ?= '/etc/security/keytabs/spnego.service.keytab'
        options.auth_opts ?= {}
        options.auth_opts['solr.kerberos.cookie.domain'] ?= "#{service.node.fqdn}"
        options.auth_opts['java.security.auth.login.config'] ?= "#{options.conf_dir}/solr-server.jaas"
        options.auth_opts['solr.kerberos.principal'] ?= options.spnego.principal
        options.auth_opts['solr.kerberos.keytab'] ?= options.spnego.keytab
        options.auth_opts['solr.kerberos.name.rules'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
        # Authentication
        #Acls
        #https://cwiki.apache.org/confluence/display/solr/Rule-Based+Authorization+Plugin
        # ACL are available from solr 5.3 version (HDP verseion has 5.2 (June-2016))
        # Configure roles & acl only on one host
        if service.deps.solr_cloud[0].node.fqdn is service.node.fqdn
          if options.source isnt 'HDP'
            unless /^[0-5].[0-2]/.test options.version # version < 5.3
              options.security["authorization"] ?= {}
              options.security["authorization"]['class'] ?= 'solr.RuleBasedAuthorizationPlugin'
              options.security["authorization"]['permissions'] ?= []
              # options.security["authorization"]['permissions'].push name: 'security-edit' , role: 'admin' #define new role
              # options.security["authorization"]['permissions'].push name: 'read' , role: 'reader' #define new role
              options.security["authorization"]['permissions'].push name: 'all' , role: 'manager' #define new role
              options.security["authorization"]['user-role'] ?= {}
              options.security["authorization"]['user-role']["#{options.admin_principal}"] ?= 'manager'
              for host in service.deps.solr_cloud.map( (srv)-> srv.node.fqdn)
                options.security["authorization"]['user-role']["#{options.user.name}/#{host}@#{options.krb5.realm}"] ?= 'manager'
                options.security["authorization"]['user-role']["HTTP/#{host}@#{options.krb5.realm}"] ?= 'manager'

### Environment and Zookeeper ACL

      options.zk_opts ?= {}
      options.env['SOLR_JAVA_HOME'] ?= service.deps.java.options.java_home if service.deps.java
      options.env['SOLR_HOST'] ?= service.node.fqdn
      options.env['ZK_HOST'] ?= options.zkhosts
      options.env['SOLR_HEAP'] ?= "512m"
      options.env['ENABLE_REMOTE_JMX_OPTS'] ?= 'false'
      if service.deps.hadoop_core[0].options.core_site['hadoop.security.authentication'] is 'kerberos'
        # options.env['SOLR_AUTHENTICATION_CLIENT_CONFIGURER'] ?= 'org.apache.options.client.solrj.impl.Krb5HttpClientConfigurer'
        options.env['SOLR_AUTH_TYPE'] ?= 'kerberos'
        # Zookeeper ACLs
        # https://cwiki.apache.org/confluence/display/solr/ZooKeeper+Access+Control
        # options.zk_opts['zkCredentialsProvider'] ?= 'org.apache.solr.common.cloud.DefaultZkCredentialsProvider'
        # options.zk_opts['zkACLProvider'] ?= 'org.apache.solr.common.cloud.SaslZkACLProvider'
        # options.zk_opts['solr.authorization.superuser'] ?= solr.user.name #default to solr
        # options.env['SOLR_ZK_CREDS_AND_ACLS'] ?= 'org.apache.solr.common.cloud.SaslZkACLProvider'
      else
        #d
      options.zk_opts['zkCredentialsProvider'] ?= 'org.apache.solr.common.cloud.VMParamsSingleSetCredentialsDigestZkCredentialsProvider'
      options.zk_opts['zkACLProvider'] ?= 'org.apache.solr.common.cloud.VMParamsAllAndReadonlyDigestZkACLProvider'
      options.zk_opts['zkDigestUsername'] ?= options.user.name
      options.zk_opts['zkDigestPassword'] ?= 'solr123'
        # options.zk_opts['zkDigestReadonlyUsername'] ?= auser
        # options.zk_opts['zkDigestReadonlyPassword'] ?= 'solr123'

## SSL

      options.ssl = mixme service.deps.ssl?.options, ssl:
        truststore: target: "#{options.conf_dir}/truststore"
        keystore: target: "#{options.conf_dir}/keystore"
      , options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" unless options.ssl.cert
        throw Error "Required Option: ssl.key" unless options.ssl.key
        throw Error "Required Option: ssl.cacert" unless options.ssl.cacert
        throw Error "Required Property: ssl.truststore.password" unless options.ssl.truststore.password
        throw Error "Required Property: keystore.password" unless options.ssl.keystore.password
        options.env['SOLR_SSL_KEY_STORE'] ?= options.ssl.keystore.target
        options.env['SOLR_SSL_KEY_STORE_PASSWORD'] ?= options.ssl.keystore.password
        options.env['SOLR_SSL_TRUST_STORE'] ?= options.ssl.truststore.target
        options.env['SOLR_SSL_TRUST_STORE_PASSWORD'] ?= options.ssl.truststore.password
        options.env['SOLR_SSL_NEED_CLIENT_AUTH'] ?= 'false'

### Java version
Solr 6.0 is compiled with java 1.8.
So it must be run with jdk 1.8.
The `options.jre_home` configuration allow a specific java version to be used by 
solr zkCli script

      options.jre_home ?= service.deps.java.options.java_home if service.deps.java

### Configure HDFS
[Configure][solr-hdfs] Solr to index document using hdfs, and document stored in HDFS.

      if service.deps.hdfs_client?
        options.hdfs ?= {}
        options.hdfs.user ?= service.deps.hadoop_core[0].options.hdfs.krb5_user
        options.hdfs.home ?=  "hdfs://#{service.deps.hadoop_core[0].options.core_site['fs.defaultFS']}/user/#{options.user.name}"
        options.hdfs.blockcache_enabled ?= 'true'
        options.hdfs.blockcache_slab_count ?= '1'
        options.hdfs.blockcache_direct_memory_allocation ?= 'false'
        options.hdfs.blockcache_blocksperbank ?= 16384
        options.hdfs.blockcache_read_enabled ?= 'true'
        options.hdfs.blockcache_write_enabled ?= false
        options.hdfs.nrtcachingdirectory_enable ?= true
        options.hdfs.nrtcachingdirectory_maxmergesizemb ?= '16'
        options.hdfs.nrtcachingdirectory_maxcachedmb ?= '192'
        options.hdfs.security_kerberos_enabled ?= if service.deps.hadoop_core[0].options.core_site['hadoop.security.authentication'] is 'kerberos' then 'true' else 'false'
        options.hdfs.security_kerberos_keytabfile ?= options.keytab
        options.hdfs.security_kerberos_principal ?= options.principal
        # instruct solr to use hdfs as home dir
        options.dir_factory = 'options.HdfsDirectoryFactory'
        options.lock_type = 'hdfs'

# Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait ?= {}
      options.wait.tcp ?= for srv in service.deps.solr_cloud
        host: srv.node.fqdn
        port: srv.options.port or '8983'

## Dependencies

    mixme = require 'mixme'

[solr-krb5]:https://cwiki.apache.org/confluence/display/solr/Kerberos+Authentication+Plugin
[solr-ssl]: https://cwiki.apache.org/confluence/display/solr/Enabling+SSL#EnablingSSL-RunSolrCloudwithSSL
[solr-auth]: https://cwiki.apache.org/confluence/display/solr/Rule-Based+Authorization+Plugin
[solr-hdfs]: http://fr.hortonworks.com/hadoop-tutorial/searching-data-solr/
[solr-6.6.]: https://lucene.apache.org/solr/guide/6_6/kerberos-authentication-plugin.html
