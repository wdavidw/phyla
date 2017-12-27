
# Knox Configure

## Configure default

This function is called if and only if no topology configuration is provided.
This function declare services if modules are present in the configuration context.
Configuration like address and port will be then enriched by the configure which
loop on topologies to provide missing values

## Configure

    module.exports = (service) ->
      options = service.options

## Environment

      # Layout
      options.conf_dir ?= '/etc/knox/conf'
      options.log_dir ?= '/var/log/knox'
      options.pid_dir ?= '/var/run/knox'
      options.bin_dir ?= '/usr/hdp/current/knox-server/bin'
      # Misc
      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'knox'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'knox'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.comment ?= 'Knox Gateway User'
      options.user.home ?= '/var/lib/knox'
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= true

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      options.krb5_user ?= {}
      options.krb5_user.principal ?= "#{options.user.name}/#{options.fqdn}@#{options.krb5.realm}"
      options.krb5_user.keytab ?= '/etc/security/keytabs/options.service.keytab'

## Test

      options.ranger_admin ?= service.deps.ranger_admin.options.admin if service.deps.ranger_admin
      options.test = merge {}, service.deps.test_user.options, options.test
      if service.deps.ranger_admin?
        service.deps.ranger_admin.options.users ?= {}
        service.deps.ranger_admin.options.users[options.test.user.name] ?=
          "name": options.test.user.name
          "firstName": options.test.user.name
          "lastName": 'hadoop'
          "emailAddress": "#{options.test.user.name}@hadoop.ryba"
          "password": options.test.user.password
          'userSource': 1
          'userRoleList': ['ROLE_USER']
          'groups': []
          'status': 1

## Env

Knox reads its own env variable to retrieve configuration.

      options.env ?= {}
      options.env.app_mem_opts ?= '-Xmx8192m'
      options.env.app_log_dir ?= "#{options.log_dir}"
      options.env.app_log_opts ?= ''
      options.env.app_dbg_opts ?= ''

## Java

      options.java_home = service.deps.java.options.java_home
      options.jre_home = service.deps.java.options.jre_home

## SSL

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      # options.truststore ?= {}
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        options.ssl.keystore.target = '/usr/hdp/current/knox-server/data/security/keystores/gateway.jks'
        # migration: lucasbak 16102017
        # knox search by default gateway-identity as default keystore
        options.ssl.key.name = 'gateway-identity'
        throw Error "Required Property: truststore.password" if not options.ssl.truststore.password
        options.ssl.truststore.caname ?= 'hadoop_root_ca'
      # options.ssl.storepass ?= 'knox_master_secret_123'
      # options.ssl.cacert ?= @config.ryba.ssl?.cacert
      # options.ssl.cert ?= @config.ryba.ssl?.cert
      # options.ssl.key ?= @config.ryba.ssl?.key
      # options.ssl.keypass ?= 'knox_master_secret_123'
      # Knox SSL
      # throw Error 'Required Options: ssl.cacert' unless options.ssl.cacert?
      # throw Error 'Required Options: ssl.cert' unless options.ssl.cert?
      # throw Error 'Required Options ssl.key' unless options.ssl.key?

## Configuration

      # Configuration
      options.gateway_site ?= {}
      options.gateway_site['gateway.port'] ?= '8443'
      options.gateway_site['gateway.path'] ?= 'gateway'
      options.gateway_site['java.security.krb5.conf'] ?= '/etc/krb5.conf'
      options.gateway_site['java.security.auth.login.config'] ?= "#{options.conf_dir}/knox.jaas"
      options.gateway_site['gateway.hadoop.kerberos.secured'] ?= 'true'
      options.gateway_site['sun.security.krb5.debug'] ?= 'true'
      options.realm_passwords = {}
      options.config ?= {}

## Proxy Users

      enrich_proxy_user = (srv) ->
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
        hosts = srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] or []
        hosts = hosts.split ',' unless Array.isArray hosts
        for instance in service.instances
          hosts.push instance.node.fqdn unless instance.node.fqdn in hosts
        hosts = hosts.join ','
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= hosts
      enrich_proxy_user srv for srv in service.deps.hdfs_nn
      enrich_proxy_user srv for srv in service.deps.hdfs_dn
      enrich_proxy_user srv for srv in service.deps.yarn_rm
      enrich_proxy_user srv for srv in service.deps.yarn_nm
      enrich_proxy_user srv for srv in service.deps.yarn_ts
      enrich_proxy_user srv for srv in service.deps.mapred_jhs
      # Probably hbase rest is reading "core-site.xml" from "/etc/hadoop/conf"
      # enrich_proxy_user srv, 'hbase_rest' for srv in service.deps.hbase_rest
      enrich_proxy_user srv, 'hdfs_client' for srv in service.deps.hdfs_client
      for srv in service.deps.httpfs
        srv.options.httpfs_site["httpfs.proxyuser.#{options.user.name}.groups"] ?= '*'
        hosts = srv.options.httpfs_site["httpfs.proxyuser.#{options.user.name}.hosts"] or ''
        hosts = hosts.split ','
        for instance in service.instances
          hosts.push instance.node.fqdn unless instance.node.fqdn in hosts
        hosts = hosts.join ' '
        srv.options.httpfs_site["httpfs.proxyuser.#{options.user.name}.hosts"] ?= hosts
      for srv in service.deps.oozie_server
        srv.options.oozie_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.groups"] ?= '*'
        hosts = srv.options.oozie_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.hosts"] or ''
        hosts = hosts.split ','
        for instance in service.instances
          hosts.push instance.node.fqdn unless instance.node.fqdn in hosts
        hosts = hosts.join ' '
        srv.options.oozie_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.hosts"] ?= hosts

## Configure topology

LDAP authentication is configured by adding a "ShiroProvider" authentication 
provider to the cluster's topology file. When enabled, the Knox Gateway uses 
Apache Shiro (org.apache.shiro.realm.ldap.JndiLdapRealm) to authenticate users 
against the configured LDAP store.
Administrators can use `myrealm.sssd_lookup` to read ldap config from `masson/core/sssd`
module. If sssd is not used, administrators should set the value of the target ldap
by setting the properties `myrealm.ldap_uri`, `myrealm.ldap_default_bind_dn`, `myrealm.ldap_default_authtok`.
By default `sssd_lookup` is false.
Inspired from [knox-repo][knox-conf-example]

Example:
```
  realms:
    ldapRealm:
      ldap_search_base: 'ou=users,dc=ryba'
      ldap_group_search_base: 'ou=groups,dc=ryba'
      ldap_uri: 'ldaps://master03.metal.ryba:636'
      ldap_tls_cacertdir: '/etc/openldap/cacerts'
      ldap_default_bind_dn: 'cn=ldapadm,dc=ryba'
      ldap_default_authtok: 'test'
      groupSearchBase:  'ou=groups,dc=ryba'
      groupIdAttribute: 'cn'
      groupObjectClass: 'posixGroup'
      memberAttribute: 'memberUId'
      memberAttributeValueTemplate: 'uid={0},ou=uses,dc=ryba'
      userDnTemplate:'cn={0},ou=users,dc=ryba'
      userSearchAttributeName: 'cn'
      userObjectClass: 'person'
```


      nameservice = service.deps.hdfs_nn[0].options.nameservice
      options.topologies ?= {}
      for nameservice, topology of options.topologies
        topology[nameservice] ?= {}
        topology[nameservice].services ?= {}
        topology[nameservice].services['namenode'] ?= !!service.deps.hdfs_nn
        topology[nameservice].services['webhdfs'] ?= !!service.deps.hdfs_nn
        topology[nameservice].services['jobtracker'] ?= !!service.deps.yarn_rm
        topology[nameservice].services['hive'] ?= !!service.deps.hive_server2
        topology[nameservice].services['webhcat'] ?= !!service.deps.hive_webhcat
        topology[nameservice].services['oozie'] ?= !!service.deps.oozie_server
        topology[nameservice].services['webhbase'] ?= !!service.deps.hbase_rest
        # Configure providers
        topology.providers ?= {}
        topology.providers['authentication'] ?= {}
        topology.providers['authentication'].name ?= 'ShiroProvider'
        topology.providers['authentication'].config ?= {}
        topology.providers['authentication'].config['sessionTimeout'] ?= 30
        # By default, we only configure a simple LDAP Binding (user only)
        # migration: wdavidw 170922, this used to be:
        # realms = 'ldapRealm': topology
        # migration: lucasbak 10102017 change how realms are configured
        throw Error 'Need One Realm when ShiroProvider is used' unless topology.realms?
        for realm, realm_config of topology.realms
          if realm_config.sssd_lookup
            throw Error 'masson/core/sssd must be used when realm.sssd_lookup is set' unless service.deps.sssd?
            throw Error "masson/core/sssd ldap domain #{realm_config.sssd_lookup} does not exist" unless service.deps.sssd.options.config[realm_config.sssd_lookup]?
            realm_config = merge {}, realm_config, service.deps.sssd.options.config[realm_config.sssd_lookup]
          else
            throw Error 'Required property ldap_uri' unless realm_config['ldap_uri']?
            throw Error 'Required property ldap_default_bind_dn' unless realm_config['ldap_default_bind_dn']?
            throw Error 'Required property ldap_default_authtok' unless realm_config['ldap_default_authtok']?
          for property in [
            'groupSearchBase'
            'groupIdAttribute'
            'groupObjectClass'
            'memberAttribute'
            'memberAttributeValueTemplate'
            'userDnTemplate'
            'userSearchAttributeName'
            'userObjectClass'
            'userSearchBase'
          ] then do ->
            topology.providers['authentication'].config["main.#{realm}.#{property}"] ?= realm_config["#{property}"] if realm_config["#{property}"]?
          #configure use ldap authentication
          topology.providers['authentication'].config["main.#{realm}"] ?= 'org.apache.hadoop.gateway.shirorealm.KnoxLdapRealm' # OpenLDAP implementation
          # topology.providers['authentication'].config['main.ldapRealm'] ?= 'org.apache.shiro.realm.ldap.JndiLdapRealm' # AD implementation
          topology.providers['authentication'].config["main.#{realm}".replace('Realm','')+"ContextFactory"] ?= 'org.apache.hadoop.gateway.shirorealm.KnoxLdapContextFactory'
          topology.providers['authentication'].config["main.#{realm}.contextFactory"] ?= '$'+"#{realm}".replace('Realm','')+'ContextFactory'

          topology.providers['authentication'].config["main.#{realm}.userDnTemplate"] = realm_config['userDnTemplate'] if realm_config['userDnTemplate']?
          topology.providers['authentication'].config["main.#{realm}.contextFactory.url"] = realm_config['ldap_uri'].split(',')[0]
          topology.providers['authentication'].config["main.#{realm}.contextFactory.systemUsername"] = realm_config['ldap_default_bind_dn']
          topology.providers['authentication'].config["main.#{realm}.contextFactory.systemPassword"] = "${ALIAS=#{nameservice}-#{realm}-password}"
          options.realm_passwords["#{nameservice}-#{realm}-password"] = realm_config['ldap_default_authtok']
          topology.providers['authentication'].config["main.#{realm}.searchBase"] = realm_config["ldap#{if realm == 'ldapGroupRealm' then '_group' else ''}_search_base"]
          topology.providers['authentication'].config["main.#{realm}.contextFactory.authenticationMechanism"] ?= 'simple'
          topology.providers['authentication'].config["main.#{realm}.authorizationEnabled"] ?= 'true'
        topology.providers['authentication'].config['urls./**'] ?= 'authcBasic'
        topology.providers['authentication'].config['main.securityManager.realms'] = ["$"+realm for realm, _ of topology.realms].join ","
        # LDAP Authentication Caching
        topology.providers['authentication'].config['main.cacheManager'] = "org.apache.shiro.cache.ehcache.EhCacheManager"
        topology.providers['authentication'].config['main.securityManager.cacheManager'] = "$cacheManager"
        topology.providers['authentication'].config['main.ldapRealm.authenticationCachingEnabled'] = true
        topology.providers['authentication'].config['main.cacheManager.cacheManagerConfigFile'] = "classpath:#{nameservice}-ehcache.xml"

The Knox Gateway identity-assertion provider maps an authenticated user to an
internal cluster user and/or group. This allows the Knox Gateway accept requests
from external users without requiring internal cluster user names to be exposed.

        topology.providers['identity-assertion'] ?= name: 'Pseudo'
        topology.providers['authorization'] ?= if service.deps.ranger_admin? then name: 'XASecurePDPKnox' else name: 'AclsAuthz'
        ## Services
        topology.services ?= {}
        topology.services.knox ?= ''

Services are auto-configured in discovery mode if they are actived (services[module] = true)
This mechanism can be used to configure a specific gateway without having to declare address and port
(that may change over time).

        # Namenode & WebHDFS
        if topology.services['namenode'] is true
          if service.deps.hdfs_nn
            topology.services['namenode'] = service.deps.hdfs_nn[0].options.core_site['fs.defaultFS']
          else throw Error 'Cannot autoconfigure KNOX namenode service, no namenode declared'  
        if topology.services['webhdfs'] is true
          throw Error 'Cannot autoconfigure KNOX webhdfs service, no namenode declared' unless service.deps.hdfs_nn
          # WebHDFS auto configuration rules:
          # We provide by default namenode WebHDFS (default implementation, embedded in namenode) instead of httpfs. Httpfs put request through knox create empty files.
          # We also configure HA for WebHDFS if namenodes are in HA-mode

          # if service.deps.httpfs
          #   if service.deps.httpfs.length > 1
          #     topology.providers['ha'] ?= name: 'HaProvider'
          #     topology.providers['ha'].config ?= {}
          #     topology.providers['ha'].config['WEBHDFS'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
          #   topology.services['webhdfs'] = service.deps.httpfs.map (srv) -> "http#{if srv.options.env.HTTPFS_SSL_ENABLED is 'true' then 's' else ''}://#{ctx.config.host}:#{ctx.config.ryba.httpfs.http_port}/webhdfs/v1"
          if service.deps.hdfs_nn.length > 1
            topology.providers['ha'] ?= name: 'HaProvider'
            topology.providers['ha'].config ?= {}
            topology.providers['ha'].config['WEBHDFS'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
            topology.services['webhdfs'] = []
            for srv in service.deps.hdfs_nn
              protocol = if srv.options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
              port = srv.options.hdfs_site["dfs.namenode.#{protocol}-address.#{srv.options.nameservice}.#{srv.node.hostname}"].split(':')[1]
              # We ensure that the default active namenode is first in the list !
              action = if srv.node.fqdn is srv.options.active_nn_host then 'unshift' else 'push'
              topology.services['webhdfs'][action] "#{protocol}://#{srv.node.fqdn}:#{port}/webhdfs"
          else
            protocol = if srv.use.hdfs_nn[0].options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
            port = srv.use.hdfs_nn[0].options.hdfs_site["dfs.namenode.#{protocol}-address"].split(':')[1]
            topology.services['webhdfs'] = "#{protocol}://#{srv.use.hdfs_nn[0].node.fqdn}:#{port}/webhdfs" 

## Yarn ResourceManager

        if topology.services['jobtracker'] is true
          if service.deps.yarn_rm
            rm_shortname = if service.deps.yarn_rm.length > 1 then ".#{service.deps.yarn_rm[0].node.hostname}" else ''
            rm_address = service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.address#{rm_shortname}"]
            rm_ws_address = service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.https.address#{rm_shortname}"]
            topology.services['jobtracker'] = "rpc://#{rm_address}"
            topology.services['RESOURCEMANAGER'] = "https://#{rm_ws_address}/ws"
          else throw Error 'Cannot autoconfigure KNOX jobtracker service, no resourcemanager declared'

## Hive Server2

        if topology.services['hive'] is true
          if service.deps.hive_server2.length is 1
            host = service.deps.hive_server2[0].node.fqdn
            port = service.deps.hive_server2[0].options.hive_site['hive.server2.thrift.http.port']
            protocol = if service.deps.hive_server2[0].options.hive_site['hive.server2.use.SSL'] is 'true' then 'https' else 'http'
            topology.services['hive'] = "#{protocol}://#{host}:#{port}/cliservice"
          else if service.deps.hive_server2.length > 1
            topology.providers['ha'] ?= name: 'HaProvider'
            topology.providers['ha'].config ?= {}
            topology.providers['ha'].config['HIVE'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;enabled=true;' + 
            "zookeeperEnsemble=#{service.deps.hive_server2[0].options.hive_site['hive.zookeeper.quorum']};zookeeperNamespace=#{service.deps.hive_server2[0].options.hive_site['hive.server2.zookeeper.namespace']}"
            topology.services.hive = ''
          else
            throw Error 'Cannot autoconfigure KNOX hive service, no hiveserver2 declared'

# Hive WebHCat

        if topology.services['webhcat'] is true
          throw Error 'Cannot autoconfigure KNOX webhcat service, no webhcat declared' unless service.deps.hive_webhcat
          topology.services['webhcat'] = []
          for srv in service.deps.hive_webhcat
            fqdn = srv.node.fqdn
            port = srv.options.webhcat_site['templeton.port']
            topology.services['webhcat'].push "http://#{fqdn}:#{port}/templeton"
          if service.deps.hive_webhcat.length > 1
            topology.providers['ha'] ?= name: 'HaProvider'
            topology.providers['ha'].config ?= {}
            topology.providers['ha'].config['WEBHCAT'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;enabled=true'

## Oozie

        if topology.services['oozie'] is true
          throw Error 'Cannot autoconfigure KNOX oozie service, no oozie declared' unless service.deps.oozie_server
          topology.services['oozie'] = []
          for srv in service.deps.oozie_server
            topology.services['oozie'].push srv.options.oozie_site['oozie.base.url']
          if service.deps.oozie_server.length > 1
            topology.providers['ha'] ?= name: 'HaProvider'
            topology.providers['ha'].config ?= {}
            topology.providers['ha'].config['OOZIE'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;enabled=true'

## WebHBase

        if topology.services['webhbase'] is true
          throw Error 'Cannot autoconfigure KNOX webhbase service, no webhbase declared' unless service.deps.hbase_rest
          topology.services['webhbase'] = []
          for srv in service.deps.hbase_rest
            protocol = if srv.options.hbase_site['hbase.rest.ssl.enabled'] is 'true' then 'https' else 'http'
            port = srv.options.hbase_site['hbase.rest.port']
            if options.config.webhbase?
              topology.services['webhbase'] =
                url: "#{protocol}://#{srv.node.fqdn}:#{port}"
                params: options.config.webhbase
            else
              topology.services['webhbase'].push "#{protocol}://#{srv.node.fqdn}:#{port}" 
          if service.deps.hbase_rest.length > 1
            topology.providers['ha'] ?= name: 'HaProvider'
            topology.providers['ha'].config ?= {}
            topology.providers['ha'].config['WEBHBASE'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;enabled=true'

## HBase

        if topology.services['hbaseui'] is true
          throw Error 'Cannot autoconfigure KNOX hbaseui service, no hbaseui declared' unless service.deps.hbase_master
          topology.services['hbaseui'] = []
          for srv in service.deps.hbase_master
            protocol = if service.deps.hbase_master.hbase_site['hbase.ssl.enabled'] is 'true' then 'https' else 'http'
            port = service.deps.hbase_master.hbase_site['hbase.master.info.port']
            topology.services['hbaseui'].push "#{protocol}://#{srv.node.fqdn}:#{port}"

## Configuration for Log4J

      options.log4j ?= merge {}, service.deps.log4j?.options, options.log4j
      options.log4j.properties ?= {}
      options.log4j.properties ?= {}
      options.log4j.properties['app.log.dir'] ?= "#{options.log_dir}"
      options.log4j.properties['log4j.rootLogger'] ?= 'ERROR,rfa'
      if options.remote_host? and options.remote_port?
        options.log4j.socket_client ?= 'SOCKET'
        # Root logger
        if options.log4j.properties['log4j.rootLogger'].indexOf(options.log4j.socket_client) is -1
        then options.log4j.properties['log4j.rootLogger'] += ",#{options.log4j.socket_client}"
        # Set java opts
        options.log4j.properties['app.log.application'] ?= 'knox'
        options.log4j.properties['app.log.remote_host'] ?= options.log4j.remote_host
        options.log4j.properties['app.log.remote_port'] ?= options.log4j.remote_port
        options.log4j.socket_opts ?=
          Application: '${app.log.application}'
          RemoteHost: '${app.log.remote_host}'
          Port: '${app.log.remote_port}'
          ReconnectionDelay: '10000'
        appender
          type: 'org.apache.log4j.net.SocketAppender'
          name: options.log4j.socket_client
          logj4: options.log4j.properties
          properties: options.log4j.socket_opts

## Wait

      options.wait_ranger_admin = service.deps.ranger_admin.options.wait if service.deps.ranger_admin
      options.wait ?= {}
      options.wait.tcp = for srv in service.deps.knox_server
        host: srv.node.fqdn
        port: options.gateway_site['gateway.port']

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'nikita/lib/misc'

[knox-conf-example]:https://github.com/apache/knox/blob/master/gateway-release/home/templates/sandbox.knoxrealm2.xml
