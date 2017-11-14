
# Hadoop Core Configuration

*   `hdfs.user` (object|string)
    The Unix HDFS login name or a user object (see Nikita User documentation).
*   `yarn.user` (object|string)
    The Unix YARN login name or a user object (see Nikita User documentation).
*   `mapred.user` (object|string)
    The Unix MapReduce login name or a user object (see Nikita User documentation).
*   `user` (object|string)
    The Unix Test user name or a user object (see Nikita User documentation).
*   `hadoop_group` (object|string)
    The Unix Hadoop group name or a group object (see Nikita Group documentation).
*   `hdfs.group` (object|string)
    The Unix HDFS group name or a group object (see Nikita Group documentation).
*   `yarn.group` (object|string)
    The Unix YARN group name or a group object (see Nikita Group documentation).
*   `mapred.group` (object|string)
    The Unix MapReduce group name or a group object (see Nikita Group documentation).
*   `group` (object|string)
    The Unix Test group name or a group object (see Nikita Group documentation).

Default configuration:

```json
{
  "ryba": {
    "user": {
      "name": "ryba", "system": true, "gid": "ryba",
      "comment": "ryba User", "home": "/home/ryba"
    },
    "group": {
      "name": "ryba", "system": true
    },
    "hdfs": {
      "user": {
        "name": "hdfs", "system": true, "gid": "hdfs",
        "comment": "HDFS User", "home": "/var/lib/hadoop-hdfs"
      },
      "group": {
        "name": "hdfs", "system": true
      }
    },
    "yarn": {
      "user": {
        "name": "yarn", "system": true, "gid": "yarn",
        "comment": "YARN User", "home": "/var/lib/hadoop-yarn"
      },
      "group": {
        "name": "yarn", "system": true
      }
    },
    "mapred": {
      "user": {
        "name": "mapred", "system": true, "gid": "mapred",
        "comment": "MapReduce User", "home": "/var/lib/hadoop-mapreduce"
      },
      "group": {
        "name": "mapred", "system": true
      }
    },
    "hadoop_group": {
      "name": "hadoop", "system": true
    }
  }
}
```

    module.exports = (service) ->
      options = service.options
      options.yarn ?= {}
      options.mapred ?= {}

## Validation

HDFS does not accept underscore "_" inside the hostname or it fails on startup 
with the log message:

```
17/05/15 00:31:54 WARN hdfs.DFSUtil: Exception in creating socket address master_01.ambari.ryba:8020
java.lang.IllegalArgumentException: Does not contain a valid host:port authority: master_01.ambari.ryba:8020
```

      throw Error "Invalid Hostname: #{service.node.fqdn} should not contain \"_\"" if /_/.test service.node.fqdn

## Environment

      # Layout
      options.conf_dir ?= '/etc/hadoop/conf'
      # options.hadoop_lib_home ?= '/usr/hdp/current/hadoop-client/lib' # refered by oozie-env.sh, now hardcoded
      options.hdfs.log_dir ?= '/var/log/hadoop-hdfs'
      options.hdfs.pid_dir ?= '/var/run/hadoop-hdfs'
      options.hdfs.secure_dn_pid_dir ?= '/var/run/hadoop-hdfs' # /$HADOOP_SECURE_DN_USER
      options.hdfs.secure_dn_user ?= options.hdfs.user.name
      # Java
      options.hadoop_opts ?= '-Djava.net.preferIPv4Stack=true'
      options.hadoop_classpath ?= ''
      options.hadoop_heap ?= '1024'
      options.hadoop_client_opts ?= '-Xmx2048m'

## HA Configuration

      # options.nameservice ?= null
      # throw Error "Invalid Service Name" unless options.nameservice

## Identities

      # Group for hadoop
      options.hadoop_group = name: options.hadoop_group if typeof options.hadoop_group is 'string'
      options.hadoop_group ?= {}
      options.hadoop_group.name ?= 'hadoop'
      options.hadoop_group.system ?= true
      options.hadoop_group.comment ?= 'Hadoop Group'
      # Groups
      options.hdfs.group ?= {}
      options.hdfs.group = name: options.hdfs.group if typeof options.hdfs.group is 'string'
      options.hdfs.group.name ?= 'hdfs'
      options.hdfs.group.system ?= true
      options.yarn.group ?= {}
      options.yarn.group = name: options.yarn.group if typeof options.yarn.group is 'string'
      options.yarn.group.name ?= 'yarn'
      options.yarn.group.system ?= true
      options.mapred.group ?= {}
      options.mapred.group = name: options.mapred.group if typeof options.mapred.group is 'string'
      options.mapred.group.name ?= 'mapred'
      options.mapred.group.system ?= true
      # Unix user hdfs
      options.hdfs.user ?= {}
      options.hdfs.user = name: options.hdfs.user if typeof options.hdfs.user is 'string'
      options.hdfs.user.name ?= 'hdfs'
      options.hdfs.user.system ?= true
      options.hdfs.user.gid = options.hdfs.group.name
      options.hdfs.user.groups ?= 'hadoop'
      options.hdfs.user.comment ?= 'Hadoop HDFS User'
      options.hdfs.user.home ?= '/var/lib/hadoop-hdfs'
      options.hdfs.user.limits ?= {}
      options.hdfs.user.limits.nofile ?= 64000
      options.hdfs.user.limits.nproc ?= true
      # Unix user for yarn
      options.yarn.user ?= {}
      options.yarn.user = name: options.yarn.user if typeof options.yarn.user is 'string'
      options.yarn.user.name ?= 'yarn'
      options.yarn.user.system ?= true
      options.yarn.user.gid = options.yarn.group.name
      options.yarn.user.groups ?= 'hadoop'
      options.yarn.user.comment ?= 'Hadoop YARN User'
      options.yarn.user.home ?= '/var/lib/hadoop-yarn'
      options.yarn.user.limits ?= {}
      options.yarn.user.limits.nofile ?= 64000
      options.yarn.user.limits.nproc ?= true
      # Unix user for mapred
      options.mapred.user ?= {}
      options.mapred.user = name: options.mapred.user if typeof options.mapred.user is 'string'
      options.mapred.user.name ?= 'mapred'
      options.mapred.user.system ?= true
      options.mapred.user.gid = options.mapred.group.name
      options.mapred.user.groups ?= 'hadoop'
      options.mapred.user.comment ?= 'Hadoop MapReduce User'
      options.mapred.user.home ?= '/var/lib/hadoop-mapreduce'
      options.mapred.user.limits ?= {}
      options.mapred.user.limits.nofile ?= 64000
      options.mapred.user.limits.nproc ?= true

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Spnego
      options.spnego ?= {}
      options.spnego.principal ?= "HTTP/#{service.node.fqdn}@#{options.krb5.realm}"
      options.spnego.keytab ?= '/etc/security/keytabs/spnego.service.keytab'
      # HDFS Super User
      options.hdfs.krb5_user ?= {}
      options.hdfs.krb5_user.principal ?= "#{options.hdfs.user.name}@#{options.krb5.realm}"
      throw Error "Required Property: hdfs.krb5_user.password" unless options.hdfs.krb5_user.password
      
## Configuration

      options.core_site ?= {}
      # Set the authentication for the cluster. Valid values are: simple or kerberos
      options.core_site['hadoop.security.authentication'] ?= 'kerberos'
      # Enable authorization for different protocols.
      options.core_site['hadoop.security.authorization'] ?= 'true'
      # A comma-separated list of protection values for secured sasl
      # connections. Possible values are authentication, integrity and privacy.
      # authentication means authentication only and no integrity or privacy;
      # integrity implies authentication and integrity are enabled; and privacy
      # implies all of authentication, integrity and privacy are enabled.
      # hadoop.security.saslproperties.resolver.class can be used to override
      # the hadoop.rpc.protection for a connection at the server side.
      options.core_site['hadoop.rpc.protection'] ?= 'authentication'
      # Default group mapping
      options.core_site['hadoop.security.group.mapping'] ?= 'org.apache.hadoop.security.JniBasedUnixGroupsMappingWithFallback'
      # Get ZooKeeper Quorum
      zookeeper_quorum = for srv in service.deps.zookeeper_server
        continue unless srv.options.config['peerType'] is 'participant'
        "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"
      options.core_site['ha.zookeeper.quorum'] ?= zookeeper_quorum

## Topology

      # Script imported from http://ofirm.wordpress.com/2014/01/09/exploring-the-hadoop-network-topology/
      options.core_site['net.topology.script.file.name'] ?= "#{options.conf_dir}/rack_topology.sh"
      options.topology = service.nodes
      .filter (node) ->
        node.services.some (service) ->
          service.module in ['ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_nm']
      .map (node) ->
        throw Error "Required Node Option: ip for node #{JSON.stringify node.id}" unless node.ip
        id: node.id, ip: node.ip, rack: node.rack
      # Validate rack
      if options.topology.some( (node) -> node.rack )
        for node in options.topology
          throw Error "Required Option: rack required in node #{node.id} because at least one rack is defined"

Configuration for HTTP

      options.core_site['hadoop.http.filter.initializers'] ?= 'org.apache.hadoop.security.AuthenticationFilterInitializer'
      options.core_site['hadoop.http.authentication.type'] ?= 'kerberos'
      options.core_site['hadoop.http.authentication.token.validity'] ?= '36000'
      options.core_site['hadoop.http.authentication.signature.secret.file'] ?= '/etc/hadoop/hadoop-http-auth-signature-secret'
      options.core_site['hadoop.http.authentication.simple.anonymous.allowed'] ?= 'false'
      options.core_site['hadoop.http.authentication.kerberos.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      options.core_site['hadoop.http.authentication.kerberos.keytab'] ?= options.spnego.keytab
      # Cluster domain
      unless options.core_site['hadoop.http.authentication.cookie.domain']
        domains = service.deps.hadoop_core.map( (srv) -> srv.node.fqdn.split('.').slice(1).join('.') ).filter( (el, pos, self) -> self.indexOf(el) is pos )
        throw Error "Multiple domains, set 'hadoop.http.authentication.cookie.domain' manually" if domains.length isnt 1
        options.core_site['hadoop.http.authentication.cookie.domain'] = domains[0]

Configuration for auth\_to\_local

The local name will be formulated from exp.
The format for exp is [n:string](regexp)s/pattern/replacement/g.
The integer n indicates how many components the target principal should have. 
If this matches, then a string will be formed from string, substituting the realm 
of the principal for $0 and the n‘th component of the principal for $n. 
If this string matches regexp, then the s//[g] substitution command will be run 
over the string. The optional g will cause the substitution to be global over 
the string, instead of replacing only the first match in the string.
The rule apply with priority order, so we write rules from the most specific to
the most general:
There is 4 identified cases:

*   The principal is a 'sub-service' principal from our internal realm. It replaces with the corresponding service name
*   The principal is from our internal realm. We apply DEFAULT rule (It takes the first component of the principal as a
    username. Only apply on the internal realm)
*   The principal is NOT from our realm, and would be mapped to an admin user like hdfs. It maps it to 'nobody'
*   The principal is NOT from our internal realm, and do NOT match any admin account.
    It takes the first component of the principal as username.

Notice that the third rule will disallow admin account on multiple clusters.
the property must be overriden in a config file to permit it. 

      esc_realm = quote options.krb5.realm
      options.core_site['hadoop.security.auth_to_local'] ?= """

            RULE:[2:$1@$0]([rn]m@#{esc_realm})s/.*/yarn/
            RULE:[2:$1@$0](jhs@#{esc_realm})s/.*/mapred/
            RULE:[2:$1@$0]([nd]n@#{esc_realm})s/.*/hdfs/
            RULE:[2:$1@$0](hm@#{esc_realm})s/.*/hbase/
            RULE:[2:$1@$0](rs@#{esc_realm})s/.*/hbase/
            RULE:[2:$1@$0](opentsdb@#{esc_realm})s/.*/hbase/
            DEFAULT
            RULE:[1:$1](yarn|mapred|hdfs|hive|hbase|oozie)s/.*/nobody/
            RULE:[2:$1](yarn|mapred|hdfs|hive|hbase|oozie)s/.*/nobody/
            RULE:[1:$1]
            RULE:[2:$1]

      """

Configuration for proxy users

      options.core_site['hadoop.proxyuser.HTTP.hosts'] ?= '*'
      options.core_site['hadoop.proxyuser.HTTP.groups'] ?= '*'

# SSL

Hortonworks mentions 2 strategies to [configure SSL][hdp_ssl], the first one
involves Self-Signed Certificate while the second one use a Certificate
Authority.

For now, only the second approach has been tested and is supported. For this, 
you are responsible for creating your own Private Key and Certificate Authority
(see bellow instructions) and for declaring with the 
"hdp.private\_key\_location" and "hdp.cacert\_location" property.

It is also recommendate to configure the 
"hdp.core\_site['ssl.server.truststore.password']" and 
"hdp.core\_site['ssl.server.keystore.password']" passwords or an error will be 
thrown.

Here's how to generate your own Private Key and Certificate Authority:

```
openssl genrsa -out hadoop.key 2048
openssl req -x509 -new -key hadoop.key -days 300 -out hadoop.pem -subj "/C=FR/ST=IDF/L=Paris/O=Adaltas/CN=adaltas.com/emailAddress=david@adaltas.com"
```

You can see the content of the root CA certificate with the command:

```
openssl x509 -text -noout -in hadoop.pem
```

You can list the content of the keystore with the command:

```
keytool -list -v -keystore truststore
keytool -list -v -keystore keystore -alias hadoop
```

[hdp_ssl]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_reference/content/ch_wire-https.html

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      if options.ssl.enabled
        options.ssl_client ?= {}
        options.ssl_server ?= {}
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        # SSL for HTTPS connection and RPC Encryption
        options.core_site['hadoop.ssl.require.client.cert'] ?= 'false'
        options.core_site['hadoop.ssl.hostname.verifier'] ?= 'DEFAULT'
        options.core_site['hadoop.ssl.keystores.factory.class'] ?= 'org.apache.hadoop.security.ssl.FileBasedKeyStoresFactory'
        options.core_site['hadoop.ssl.server.conf'] ?= 'ssl-server.xml'
        options.core_site['hadoop.ssl.client.conf'] ?= 'ssl-client.xml'

### SSL Client

The "ssl_client" options store information used to write the "ssl-client.xml"
file in the Hadoop XML configuration format. Some information are derived the 
the truststore options exported from the SSL service and merged above:

```json
{ password: 'Truststore123-',
  target: '/etc/security/jks/truststore.jks',
  caname: 'ryba_root_ca' }
```

        options.ssl_client['ssl.client.truststore.password'] ?= options.ssl.truststore.password
        throw Error "Required Option: ssl_client['ssl.client.truststore.password']" unless options.ssl_client['ssl.client.truststore.password']
        options.ssl_client['ssl.client.truststore.location'] ?= "#{options.conf_dir}/truststore"
        options.ssl_client['ssl.client.truststore.type'] ?= 'jks'

### SSL Server

The "ssl_server" options store information used to write the "ssl-server.xml"
file in the Hadoop XML configuration format. Some information are derived the 
the keystore options exported from the SSL service and merged above:

```json
{ password: 'Keystore123-',
  keypass: 'Keystore123-',
  target: '/etc/security/jks/keystore.jks',
  name: 'master01',
  caname: 'ryba_root_ca' },
```

        options.ssl_server['ssl.server.keystore.password'] ?= options.ssl.keystore.password
        throw Error "Required Option: ssl_server['ssl.server.keystore.password']" unless options.ssl_server['ssl.server.keystore.password']
        options.ssl_server['ssl.server.keystore.location'] ?= "#{options.conf_dir}/keystore"
        options.ssl_server['ssl.server.keystore.type'] ?= 'jks'
        options.ssl_server['ssl.server.keystore.keypassword'] ?= options.ssl.keystore.keypass
        throw Error "Required Option: ssl_server['ssl.server.keystore.keypassword']" unless options.ssl_server['ssl.server.keystore.keypassword']
        options.ssl_server['ssl.server.truststore.location'] ?= "#{options.conf_dir}/truststore"
        options.ssl_server['ssl.server.truststore.password'] ?= options.ssl_client['ssl.client.truststore.password']
        options.ssl_server['ssl.server.truststore.type'] ?= 'jks'

## Metrics

Configuration of Hadoop metrics system. 

The File sink is activated by default. The Ganglia and Graphite sinks are
automatically activated if the "ryba/retired/ganglia/collecto" and
"ryba/graphite/collector" are respectively registered on one of the nodes of the
cluster. You can disable any of those sinks by setting its class to false, here
how:

```json
{ "ryba": { "metrics": 
  "*.sink.file.class": false,
  "*.sink.ganglia.class": false, 
  "*.sink.graphite.class": false
 } }
```

Metric prefix can be defined globally with the usage of glob expression or per
context. Here's an exemple:

```json
{ "metrics":
    config:
      "*.sink.*.metrics_prefix": "default",
      "*.sink.file.metrics_prefix": "file_prefix", 
      "namenode.sink.ganglia.metrics_prefix": "master_prefix",
      "resourcemanager.sink.ganglia.metrics_prefix": "master_prefix"
}
```

Syntax is "[prefix].[source|sink].[instance].[options]".  According to the
source code, the list of supported prefixes is: "namenode", "resourcemanager",
"datanode", "nodemanager", "maptask", "reducetask", "journalnode",
"historyserver", "nimbus", "supervisor".

      options.metrics = merge {}, service.deps.metrics?.options, options.metrics

      # Hadoop metrics
      options.metrics ?= {}
      options.metrics.sinks ?= {}
      options.metrics.sinks.file_enabled ?= true
      options.metrics.sinks.ganglia_enabled ?= false
      options.metrics.sinks.graphite_enabled ?= false
      # default sampling period, in seconds
      options.metrics.config ?= {}
      options.metrics.config ?= {}
      options.metrics.config['*.period'] ?= '60'
      # File sink
      if options.metrics.sinks.file_enabled
        options.metrics.config["*.sink.file.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.file.config if service.deps.metrics?.options?.sinks?.file_enabled
        options.metrics.config['nodemanager.sink.file.filename'] ?= 'nodemanager-metrics.out'
        options.metrics.config['mrappmaster.sink.file.filename'] ?= 'mrappmaster-metrics.out'
        options.metrics.config['jobhistoryserver.sink.file.filename'] ?= 'jobhistoryserver-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if options.metrics.sinks.ganglia_enabled
        options.metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of options.sinks.ganglia.config if service.deps.metrics?.options?.sinks?.ganglia_enabled
      # Graphite Sink
      if options.metrics.sinks.graphite_enabled
        throw Error 'Unvalid metrics sink, please provide ryba.metrics.sinks.graphite.config.server_host and server_port' unless options.metrics.sinks.graphite.config.server_host? and options.metrics.sinks.graphite.config.server_port?
        options.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of service.deps.metrics.options.sinks.graphite.config if service.deps.metrics?.options?.sinks?.graphite_enabled

## Log4j

      options.log4j = merge {}, service.deps.log4j?.options, options.log4j
      options.log4j.hadoop_root_logger ?= 'INFO,RFA'
      options.log4j.hadoop_security_logger ?= 'INFO,RFAS'
      options.log4j.hadoop_audit_logger ?= 'INFO,RFAAUDIT'

## Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
    {merge} = require 'nikita/lib/misc'
