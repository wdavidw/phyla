
# Knox Configure

## Configure default

This function is called if and only if no topology configuration is provided.
This function declare services if modules are present in the configuration context.
Configuration like address and port will be then enriched by the configure which
loop on topologies to provide missing values

    configure_default = () ->
      services = {}
      for service, mod of {
        'namenode': 'ryba/hadoop/hdfs_nn'
        'webhdfs': 'ryba/hadoop/hdfs_nn'
        'jobtracker': 'ryba/hadoop/yarn_rm'
        'hive': 'ryba/hive/server2'
        'webhcat': 'ryba/hive/webhcat'
        'oozie': 'ryba/oozie/server'
        'webhbase': 'ryba/hbase/rest'
      } then if @contexts(mod).length > 0
        services[service] = true 
      return "#{@config.ryba.nameservice}": services: services

## Configure

    module.exports = ->
      nn_ctxs = @contexts 'ryba/hadoop/hdfs_nn'
      knox = @config.ryba.knox ?= {}
      {ssl} = @config

## Environment

      knox.conf_dir ?= '/etc/knox/conf'
      knox.log_dir ?= '/var/log/knox'
      knox.bin_dir ?= '/usr/hdp/current/knox-server/bin'

## Identities

      # Group
      knox.group = name: knox.group if typeof knox.group is 'string'
      knox.group ?= {}
      knox.group.name ?= 'knox'
      knox.group.system ?= true
      # User
      knox.user = name: knox.user if typeof knox.user is 'string'
      knox.user ?= {}
      knox.user.name ?= 'knox'
      knox.user.gid = knox.group.name
      knox.user.system ?= true
      knox.user.comment ?= 'Knox Gateway User'
      knox.user.home ?= '/var/lib/knox'

## Kerberos

      knox.krb5_user ?= {}
      knox.krb5_user.principal ?= "#{knox.user.name}/#{@config.host}@#{@config.ryba.realm}"
      knox.krb5_user.keytab ?= '/etc/security/keytabs/knox.service.keytab'
      # Env
      # Knox reads its own env variable to read configuration.
      knox.env ?= {}
      knox.env.app_mem_opts ?= '-Xmx8192m'
      knox.env.app_log_dir ?= "#{knox.log_dir}"
      knox.env.app_log_opts ?= ''
      knox.env.app_dbg_opts ?= ''
      # Configuration
      knox.site ?= {}
      knox.site['gateway.port'] ?= '8443'
      knox.site['gateway.path'] ?= 'gateway'
      knox.site['java.security.krb5.conf'] ?= '/etc/krb5.conf'
      knox.site['java.security.auth.login.config'] ?= "#{knox.conf_dir}/knox.jaas"
      knox.site['gateway.hadoop.kerberos.secured'] ?= 'true'
      knox.site['sun.security.krb5.debug'] ?= 'true'
      knox.ssl ?= ssl
      knox.ssl.storepass ?= 'knox_master_secret_123'
      knox.ssl.cacert ?= @config.ryba.ssl?.cacert
      knox.ssl.cert ?= @config.ryba.ssl?.cert
      knox.ssl.key ?= @config.ryba.ssl?.key
      knox.ssl.keypass ?= 'knox_master_secret_123'
      # Knox SSL
      throw Error 'Required property "ryba.knox.ssl.cacert"' unless knox.ssl.cacert?
      throw Error 'Required property "ryba.knox.ssl.cert"' unless knox.ssl.cert?
      throw Error 'Required property "ryba.knox.ssl.key"' unless knox.ssl.key?
      knox.topologies ?= configure_default.call @
      knox.realm_passwords = {}
      knox.config ?= {}

## Configuration for Proxy Users

      knox_hosts = @contexts('ryba/knox').map((ctx) -> ctx.config.host).join ','
      hadoop_ctxs = @contexts ['ryba/hadoop/hdfs_nn', 'ryba/hadoop/hdfs_dn', 'ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{knox.user.name}.hosts"] ?= knox_hosts
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{knox.user.name}.groups"] ?= '*'
      httpfs_ctxs = @contexts 'ryba/hadoop/httpfs'
      for httpfs_ctx in httpfs_ctxs
        httpfs_ctx.config.ryba ?= {}
        httpfs_ctx.config.ryba.httpfs ?= {}
        httpfs_ctx.config.ryba.httpfs.site ?= {}
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{knox.user.name}.hosts"] ?= knox_hosts
        httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{knox.user.name}.groups"] ?= '*'
      oozie_ctxs = @contexts 'ryba/oozie/server'
      for oozie_ctx in oozie_ctxs
        oozie_ctx.config.ryba ?= {}
        oozie_ctx.config.ryba.oozie ?= {}
        oozie_ctx.config.ryba.oozie.site ?= {}
        oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{knox.user.name}.hosts"] ?= knox_hosts
        oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{knox.user.name}.groups"] ?= '*'
      hbase_rest_ctxs = @contexts 'ryba/hbase/rest'
      for hbase_ctx in hbase_rest_ctxs
        hbase_ctx.config.ryba ?= {}
        hbase_ctx.config.ryba.core_site ?= {}
        hbase_ctx.config.ryba.core_site["hadoop.proxyuser.#{knox.user.name}.hosts"] ?= knox_hosts
        hbase_ctx.config.ryba.core_site["hadoop.proxyuser.#{knox.user.name}.groups"] ?= '*'

## Configure topology

LDAP authentication is configured by adding a "ShiroProvider" authentication 
provider to the cluster's topology file. When enabled, the Knox Gateway uses 
Apache Shiro (org.apache.shiro.realm.ldap.JndiLdapRealm) to authenticate users 
against the configured LDAP store.

      for nameservice,topology of knox.topologies
        topology ?= {}
        # Configure providers
        topology.providers ?= {}
        ldap = topology.providers['authentication'] ?= {}
        ldap.name ?= 'ShiroProvider'
        ldap.config ?= {}
        ldap.config['sessionTimeout'] ?= 30
        # By default, we only configure a simple LDAP Binding (user only)
        realms = 'ldapRealm': topology
        if topology.group
          realms['ldapGroupRealm'] = if topology.group.lookup? then @config.sssd.config[topology.group.lookup] else topology.group
        for realm, realm_config of realms
          ldap.config["main.#{realm}"] ?= 'org.apache.hadoop.gateway.shirorealm.KnoxLdapRealm' # OpenLDAP implementation
          # ldap.config['main.ldapRealm'] ?= 'org.apache.shiro.realm.ldap.JndiLdapRealm' # AD implementation
          ldap.config["main.#{realm}".replace('Realm','')+"ContextFactory"] ?= 'org.apache.hadoop.gateway.shirorealm.KnoxLdapContextFactory'
          ldap.config["main.#{realm}.contextFactory"] ?= '$'+"#{realm}".replace('Realm','')+'ContextFactory'
          # ctxs = @contexts 'masson/core/openldap_server'
          throw Error 'Required property ldap_uri' unless realm_config['ldap_uri']?
          throw Error 'Required property ldap_default_bind_dn' unless realm_config['ldap_default_bind_dn']?
          throw Error 'Required property ldap_default_authtok' unless realm_config['ldap_default_authtok']?
          throw Error 'Required property ldap_search_base' unless realm_config['ldap_search_base']?
          throw Error 'Required property ldap_search_base' if realm is 'ldapGroupRealm' and not realm_config['ldap_group_search_base']?
          ldap.config["main.#{realm}.userDnTemplate"] = realm_config['userDnTemplate'] if realm_config['userDnTemplate']?
          ldap.config["main.#{realm}.contextFactory.url"] = realm_config['ldap_uri'].split(',')[0]
          ldap.config["main.#{realm}.contextFactory.systemUsername"] = realm_config['ldap_default_bind_dn']
          ldap.config["main.#{realm}.contextFactory.systemPassword"] = "${ALIAS=#{nameservice}-#{realm}-password}"

          knox.realm_passwords["#{nameservice}-#{realm}-password"] = realm_config['ldap_default_authtok']

          ldap.config["main.#{realm}.searchBase"] = realm_config["ldap#{if realm == 'ldapGroupRealm' then '_group' else ''}_search_base"]
          ldap.config["main.#{realm}.contextFactory.authenticationMechanism"] ?= 'simple'
          ldap.config["main.#{realm}.authorizationEnabled"] ?= 'true'
        # we redo the test here, so that these params are rendered at the end of the authentication provider section 
        if topology.group?
          ldap.config['main.ldapGroupRealm.groupObjectClass'] = topology.group['groupObjectClass'] ?= "posixGroup"
          ldap.config['main.ldapGroupRealm.memberAttribute'] = topology.group['memberAttribute'] ?= "memberUid"
          ldap.config['main.ldapGroupRealm.memberAttributeValueTemplate'] = 'uid={0},' + topology['ldap_search_base']
        ldap.config['urls./**'] ?= 'authcBasic'
        ldap.config['main.securityManager.realms'] = ["$"+realm for realm, _ of realms].join "," if topology.group?

        # LDAP Authentication Caching
        ldap.config['main.cacheManager'] = "org.apache.shiro.cache.ehcache.EhCacheManager"
        ldap.config['main.securityManager.cacheManager'] = "$cacheManager"
        ldap.config['main.ldapRealm.authenticationCachingEnabled'] = true
        ldap.config['main.cacheManager.cacheManagerConfigFile'] = "classpath:#{nameservice}-ehcache.xml"

The Knox Gateway identity-assertion provider maps an authenticated user to an
internal cluster user and/or group. This allows the Knox Gateway accept requests
from external users without requiring internal cluster user names to be exposed.

        topology.providers['identity-assertion'] ?= name: 'Pseudo'
        topology.providers['authorization'] ?= name: 'AclsAuthz'
        ## Services
        topology.services ?= {}
        topology.services.knox ?= ''

Services are auto-configured in discovery mode if they are actived (services[module] = true)
This mechanism can be used to configure a specific gateway without having to declare address and port
(that may change over time).

        # Namenode & WebHDFS
        if topology.services['namenode'] is true
          if nn_ctxs.length
            topology.services['namenode'] = nn_ctxs[0].config.ryba.core_site['fs.defaultFS']
          else throw Error 'Cannot autoconfigure KNOX namenode service, no namenode declared'  
        if topology.services['webhdfs'] is true
          throw Error 'Cannot autoconfigure KNOX webhdfs service, no namenode declared' unless nn_ctxs.length
          # WebHDFS auto configuration rules:
          # We provide by default namenode WebHDFS (default implementation, embedded in namenode) instead of httpfs. Httpfs put request through knox create empty files.
          # We also configure HA for WebHDFS if namenodes are in HA-mode

          # fs_ctxs = @contexts 'ryba/hadoop/httpfs', require('../hadoop/httpfs/configure').handler
          # if fs_ctxs.length
          #   if fs_ctxs.length > 1
          #     topology.providers['ha'] ?= name: 'HaProvider'
          #     topology.providers['ha'].config ?= {}
          #     topology.providers['ha'].config['WEBHDFS'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
          #   topology.services['webhdfs'] = fs_ctxs.map (ctx) -> "http#{if ctx.config.ryba.httpfs.env.HTTPFS_SSL_ENABLED is 'true' then 's' else ''}://#{ctx.config.host}:#{ctx.config.ryba.httpfs.http_port}/webhdfs/v1"
          if nn_ctxs.length > 1
            topology.providers['ha'] ?= name: 'HaProvider'
            topology.providers['ha'].config ?= {}
            topology.providers['ha'].config['WEBHDFS'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
            topology.services['webhdfs'] = []
            for nn_ctx in nn_ctxs
              protocol = if nn_ctx.config.ryba.hdfs.nn.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
              host = nn_ctx.config.host
              shortname = nn_ctx.config.shortname
              port = nn_ctx.config.ryba.hdfs.nn.site["dfs.namenode.#{protocol}-address.#{nn_ctx.config.ryba.nameservice}.#{shortname}"].split(':')[1]
              # We ensure that the default active namenode is first in the list !
              action = if host is nn_ctx.config.ryba.active_nn_host then 'unshift' else 'push'
              topology.services['webhdfs'][action] "#{protocol}://#{host}:#{port}/webhdfs"
          else
            protocol = if nn_ctxs[0].config.ryba.hdfs.nn.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
            host = nn_ctxs[0].config.host
            port = nn_ctxs[0].config.ryba.hdfs.nn.site["dfs.namenode.#{protocol}-address"].split(':')[1]
            topology.services['webhdfs'] = "#{protocol}://#{host}:#{port}/webhdfs" 
        # Jobtracker
        if topology.services['jobtracker'] is true
          ctxs = @contexts 'ryba/hadoop/yarn_rm'
          if ctxs.length
            rm_shortname = if ctxs.length > 1 then ".#{ctxs[0].config.shortname}" else ''
            rm_address = ctxs[0].config.ryba.yarn.site["yarn.resourcemanager.address#{rm_shortname}"]
            rm_ws_address = ctxs[0].config.ryba.yarn.rm.site["yarn.resourcemanager.webapp.https.address#{rm_shortname}"]
            topology.services['jobtracker'] = "rpc://#{rm_address}"
            topology.services['RESOURCEMANAGER'] = "https://#{rm_ws_address}/ws"
          else throw Error 'Cannot autoconfigure KNOX jobtracker service, no resourcemanager declared'
        # Hive
        if topology.services['hive'] is true
          hs2_ctxs = @contexts 'ryba/hive/server2'
          if hs2_ctxs.length > 1 
            topology.providers['ha'] ?= name: 'HaProvider'
            topology.providers['ha'].config ?= {}
            topology.providers['ha'].config['HIVE'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;enabled=true;' + 
            "zookeeperEnsemble=#{hs2_ctxs[0].config.ryba.hive.server2.site['hive.zookeeper.quorum']};zookeeperNamespace=#{hs2_ctxs[0].config.ryba.hive.server2.site['hive.server2.zookeeper.namespace']}"
            
            topology.services.hive = ''
          else if hs2_ctxs.length == 1
            host = hs2_ctxs[0].config.host
            port = hs2_ctxs[0].config.ryba.hive.server2.site['hive.server2.thrift.http.port']
            protocol = if hs2_ctxs[0].config.ryba.hive.server2.site['hive.server2.use.SSL'] is 'true' then 'https' else 'http'
            topology.services['hive'] = "#{protocol}://#{host}:#{port}/cliservice"
          else
            throw Error 'Cannot autoconfigure KNOX hive service, no hiveserver2 declared'
        # Hive WebHCat
        if topology.services['webhcat'] is true
          ctxs = @contexts 'ryba/hive/webhcat'
          if ctxs.length >= 1
            topology.services['webhcat'] = []
            for ctx in ctxs
              host = ctx.config.host
              port = ctx.config.ryba.webhcat.site['templeton.port']
              topology.services['webhcat'].push "http://#{host}:#{port}/templeton"
            if ctxs.length > 1
              topology.providers['ha'] ?= name: 'HaProvider'
              topology.providers['ha'].config ?= {}
              topology.providers['ha'].config['WEBHCAT'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;enabled=true'
          else throw Error 'Cannot autoconfigure KNOX webhcat service, no webhcat declared'
        # Oozie
        if topology.services['oozie'] is true
          ctxs = @contexts 'ryba/oozie/server'
          if ctxs.length >= 1
            topology.services['oozie'] = []
            for ctx in ctxs
              topology.services['oozie'].push ctx.config.ryba.oozie.site['oozie.base.url']

            if ctxs.length > 1
              topology.providers['ha'] ?= name: 'HaProvider'
              topology.providers['ha'].config ?= {}
              topology.providers['ha'].config['OOZIE'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;enabled=true'
          else throw Error 'Cannot autoconfigure KNOX oozie service, no oozie declared'
        # WebHBase
        if topology.services['webhbase'] is true
          ctxs = @contexts 'ryba/hbase/rest'
          if ctxs.length >= 1
            topology.services['webhbase'] = []
            for ctx in ctxs
              protocol = if ctx.config.ryba.hbase.rest.site['hbase.rest.ssl.enabled'] is 'true' then 'https' else 'http'
              host = ctx.config.host
              port = ctx.config.ryba.hbase.rest.site['hbase.rest.port']
              if knox.config.webhbase?
                topology.services['webhbase'] = 
                  url: "#{protocol}://#{host}:#{port}"
                  params: knox.config.webhbase
              else
                topology.services['webhbase'].push "#{protocol}://#{host}:#{port}" 

            if ctxs.length > 1
              topology.providers['ha'] ?= name: 'HaProvider'
              topology.providers['ha'].config ?= {}
              topology.providers['ha'].config['WEBHBASE'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;enabled=true'
          else throw Error 'Cannot autoconfigure KNOX webhbase service, no webhbase declared'

        # HBase UI
        if topology.services['hbaseui'] is true
          ctxs = @contexts 'ryba/hbase/master'
          if ctxs.length >= 1
            topology.services['hbaseui'] = []
            for ctx in ctxs
              protocol = if ctx.config.ryba.hbase.master.site['hbase.ssl.enabled'] is 'true' then 'https' else 'http'
              host = ctx.config.host
              port = ctx.config.ryba.hbase.master.site['hbase.master.info.port']
              topology.services['hbaseui'].push "#{protocol}://#{host}:#{port}" 

          else throw Error 'Cannot autoconfigure KNOX hbaseui service, no hbaseui declared'

## Configuration for Log4J

      knox.log4j ?= {}
      knox.log4jopts ?= {}
      knox.log4jopts['app.log.dir'] ?= "#{knox.log_dir}"
      knox.log4jopts['log4j.rootLogger'] ?= 'ERROR,rfa'
      if @config.log4j?.services?
        if @config.log4j?.remote_host? and @config.log4j?.remote_port? and ('ryba/knox' in @config.log4j?.services)
          knox.socket_client ?= 'SOCKET'
          # Root logger
          if knox.log4jopts['log4j.rootLogger'].indexOf(knox.socket_client) is -1
          then knox.log4jopts['log4j.rootLogger'] += ",#{knox.socket_client}"
          # Set java opts
          knox.log4jopts['app.log.application'] ?= 'knox'
          knox.log4jopts['app.log.remote_host'] ?= @config.log4j.remote_host
          knox.log4jopts['app.log.remote_port'] ?= @config.log4j.remote_port
          knox.socket_opts ?=
            Application: '${app.log.application}'
            RemoteHost: '${app.log.remote_host}'
            Port: '${app.log.remote_port}'
            ReconnectionDelay: '10000'
          knox.log4j = merge knox.log4j, appender
            type: 'org.apache.log4j.net.SocketAppender'
            name: knox.socket_client
            logj4: knox.log4j
            properties: knox.socket_opts

## Dependencies

    appender = require '../lib/appender'
    {merge} = require 'nikita/lib/misc'
