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

    module.exports = (options) ->
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
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.system ?= true
      options.user.comment ?= 'Solr User'
      options.user.groups ?= 'hadoop'
      options.user.gid ?= options.group.name

## Environment

      options.single ?= {}
      options.single.version ?= '6.3.0'
      options.single.source ?= "http://apache.mirrors.ovh.net/ftp.apache.org/dist/lucene/solr/#{options.single.version}/solr-#{options.single.version}.tgz"
      options.single.root_dir ?= '/usr'
      options.single.install_dir ?= "#{options.single.root_dir}/solr/#{options.single.version}"
      options.single.latest_dir ?= "#{options.single.root_dir}/solr/current"
      options.single.latest_dir = '/opt/lucidworks-hdpsearch/solr' if options.single.source is 'HDP'
      options.single.pid_dir ?= '/var/run/solr'
      options.single.log_dir ?= '/var/log/solr'
      options.single.conf_dir ?= '/etc/solr/conf'
      # Misc
      options.hostname = service.node.hostname

## Core Conf
Ryba installs solrcloud with a single instance (one core).
However, once installed, the user can start easily several instances for 
differents cores ( and so with different ports).

      # Layout
      options.single.env ?= {}
      options.single.dir_factory ?= "${solr.directoryFactory:solr.NRTCachingDirectoryFactory}"
      options.single.lock_type = 'native'

## Fix Conf

Before 6.0 version, solr.xml'<solrCloud> section has a mistake:
The property `zkCredentialsProvider` is named `zkCredientialsProvider`

      options.single.conf_source = if (options.single.version.split('.')[0] < 6) or (options.single.source is 'HDP')
      then "#{__dirname}/../resources/standalone/solr_5.xml.j2"
      else "#{__dirname}/../resources/standalone/solr_6.xml.j2"

## Security

      if  @config.ryba.security is 'kerberos'
        options.single.principal ?= "#{options.user.name}/#{@config.host}@#{realm}"
        options.single.keytab ?= '/etc/security/keytabs/solr.single.service.keytab'


## SSL

      options.single.ssl ?= {}
      options.single.ssl.enabled ?= true
      options.single.port ?= if options.single.ssl.enabled then 9983 else 8983
      options.single.ssl_truststore_path ?= "#{options.single.conf_dir}/truststore"
      options.single.ssl_truststore_pwd ?= 'solr123'
      options.single.ssl_keystore_path ?= "#{options.single.conf_dir}/keystore"
      options.single.ssl_keystore_pwd ?= 'solr123'

### Environment

      options.single.env['SOLR_JAVA_HOME'] ?= java.java_home
      options.single.env['SOLR_HOST'] ?= @config.host
      options.single.env['SOLR_HEAP'] ?= "512m"
      options.single.env['SOLR_PORT'] ?= "#{options.single.port}"
      options.single.env['ENABLE_REMOTE_JMX_OPTS'] ?= 'false'
      if options.single.ssl.enabled
        options.single.env['SOLR_SSL_KEY_STORE'] ?= options.single.ssl_keystore_path
        options.single.env['SOLR_SSL_KEY_STORE_PASSWORD'] ?= options.single.ssl_keystore_pwd
        options.single.env['SOLR_SSL_TRUST_STORE'] ?= options.single.ssl_truststore_path
        options.single.env['SOLR_SSL_TRUST_STORE_PASSWORD'] ?= options.single.ssl_truststore_pwd
        options.single.env['SOLR_SSL_NEED_CLIENT_AUTH'] ?= 'false'
      # if ryba.security is 'kerberos'
      #   options.single.env['SOLR_AUTHENTICATION_CLIENT_CONFIGURER'] ?= 'org.apache.options.client.solrj.impl.Krb5HttpClientConfigurer'

### Java version
Solr 6.0 is compiled with java 1.8.
So it must be run with jdk 1.8.
The `single.jre_home` configuration allow a specific java version to be used by 
solr zkCli script

      options.single.jre_home ?= java.jre_home

### Configure HDFS
[Configure][solr-hdfs] Solr to index document using hdfs, and document stored in HDFS.

      nn_ctxs = @contexts '@rybajs/metal/hadoop/hdfs_nn' , require('../../hadoop/hdfs_nn/configure').handler
      if nn_ctxs.length > 0
        options.single.hdfs ?= {}
        options.single.hdfs.home ?=  "hdfs://#{nn_ctxs[0].config.ryba.core_site['fs.defaultFS']}/user/#{options.user.name}"
        options.single.hdfs.blockcache_enabled ?= 'true'
        options.single.hdfs.blockcache_slab_count ?= '1'
        options.single.hdfs.blockcache_direct_memory_allocation ?= 'false'
        options.single.hdfs.blockcache_blocksperbank ?= 16384
        options.single.hdfs.blockcache_read_enabled ?= 'true'
        options.single.hdfs.blockcache_write_enabled ?= false
        options.single.hdfs.nrtcachingdirectory_enable ?= true
        options.single.hdfs.nrtcachingdirectory_maxmergesizemb ?= '16'
        options.single.hdfs.nrtcachingdirectory_maxcachedmb ?= '192'
        options.single.hdfs.security_kerberos_enabled ?= if @config.ryba.security is 'kerberos' then true else fase
        options.single.hdfs.security_kerberos_keytabfile ?= options.single.keytab
        options.single.hdfs.security_kerberos_principal ?= options.single.principal
        # instruct solr to use hdfs as home dir
        options.single.dir_factory = 'solr.HdfsDirectoryFactory'
        options.single.lock_type = 'hdfs'

## Dependencies

    path = require 'path'

[solr-krb5]:https://cwiki.apache.org/confluence/display/solr/Kerberos+Authentication+Plugin
[solr-ssl]: https://cwiki.apache.org/confluence/display/solr/Enabling+SSL#EnablingSSL-RunSolrCloudwithSSL
[solr-auth]: https://cwiki.apache.org/confluence/display/solr/Rule-Based+Authorization+Plugin
[solr-hdfs]: http://fr.hortonworks.com/hadoop-tutorial/searching-data-solr/
