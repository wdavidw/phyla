
# Knox Configure

## Configure default

This function is called if and only if no topology configuration is provided.
This function declare services if modules are present in the configuration context.
Configuration like address and port will be then enriched by the configure which
loop on topologies to provide missing values

## Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/ambari/server', ['ryba', 'ambari', 'server', 'standalone'], require('nikita/lib/misc').merge require('.').use,
        # ssl: key: ['ssl']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        # db_admin: key: ['ryba', 'db_admin']
        # hadoop_core: key: ['ryba']
        # ambari_repo: key: ['ryba', 'ambari', 'repo']
        hdfs_nn: key: ['ryba', 'hdfs', 'nn']
        hdfs_dn: key: ['ryba', 'hdfs', 'dn']
        httpfs: key: ['ryba', 'httpfs']
        # yarn_ts: key: ['ryba', 'yarn', 'ats']
        yarn_rm: key: ['ryba', 'yarn', 'rm']
        yarn_nm: key: ['ryba', 'yarn', 'nm']
        hive_server2: key: ['ryba', 'hive', 'server2']
        hive_webhcat: key: ['ryba', 'ranger', 'hive']
        oozie_server: key: ['ryba', 'oozie', 'server']
        hbase_rest: key: ['ryba', 'oozie', 'server']
        knox: key: ['ryba', 'knox']
      @config.ryba ?= {}
      @config.ryba.ambari ?= {}
      options = @config.ryba.ambari.server.standalone = service.options

## Environment

      options.conf_dir ?= '/etc/knox/conf'
      options.log_dir ?= '/var/log/knox'
      options.bin_dir ?= '/usr/hdp/current/knox-server/bin'
      options.fqdn = service.use.fqdn

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

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]
      options.krb5_user ?= {}
      options.krb5_user.principal ?= "#{options.user.name}/#{options.fqdn}@#{options.krb5.realm}"
      options.krb5_user.keytab ?= '/etc/security/keytabs/options.service.keytab'

## Env

Knox reads its own env variable to retrieve configuration.

      options.env ?= {}
      options.env.app_mem_opts ?= '-Xmx8192m'
      options.env.app_log_dir ?= "#{options.log_dir}"
      options.env.app_log_opts ?= ''
      options.env.app_dbg_opts ?= ''

## Java

      options.java_home = service.use.java.options.java_home
      options.jre_home = service.use.java.options.jre_home

## SSL

      options.ssl ?= {}
      options.ssl.storepass ?= 'knox_master_secret_123'
      options.ssl.cacert ?= @config.ryba.ssl?.cacert
      options.ssl.cert ?= @config.ryba.ssl?.cert
      options.ssl.key ?= @config.ryba.ssl?.key
      options.ssl.keypass ?= 'knox_master_secret_123'
      # Knox SSL
      throw Error 'Required Options: ssl.cacert' unless options.ssl.cacert?
      throw Error 'Required Options: ssl.cert' unless options.ssl.cert?
      throw Error 'Required Options ssl.key' unless options.ssl.key?

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

      enrich_proxy_user (srv) ->
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
        hosts = srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] or ''
        hosts = hosts.split ','
        for fqdn in service.nodes.fqdn
          hosts.push fqdn unless fqdn in hosts
        hosts = hosts.join ' '
        srv.options.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= hosts
      enrich_proxy_user srv for srv in service.use.hdfs_nn
      enrich_proxy_user srv for srv in service.use.hdfs_dn
      enrich_proxy_user srv for srv in service.use.yarn_rm
      enrich_proxy_user srv for srv in service.use.yarn_nm
      enrich_proxy_user srv for srv in service.use.hdfs_nn
      enrich_proxy_user srv for srv in service.use.hdfs_nn
      enrich_proxy_user srv for srv in service.use.hbase_rest
      httpfs_ctxs = @contexts 'ryba/hadoop/httpfs'
      for srv in service.use.httpfs
        srv.options.httpfs_site["httpfs.proxyuser.#{options.user.name}.groups"] ?= '*'
        hosts = srv.options.httpfs_site["httpfs.proxyuser.#{options.user.name}.hosts"] or ''
        hosts = hosts.split ','
        for fqdn in service.nodes.fqdn
          hosts.push fqdn unless fqdn in hosts
        hosts = hosts.join ' '
        srv.options.httpfs_site["httpfs.proxyuser.#{options.user.name}.hosts"] ?= hosts
      for srv in service.user.oozie_server
        srv.options.httpfs_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.groups"] ?= '*'
        hosts = srv.options.httpfs_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.hosts"] or ''
        hosts = hosts.split ','
        for fqdn in service.nodes.fqdn
          hosts.push fqdn unless fqdn in hosts
        hosts = hosts.join ' '
        srv.options.oozie_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.hosts"] ?= hosts

## Configure topology

LDAP authentication is configured by adding a "ShiroProvider" authentication 
provider to the cluster's topology file. When enabled, the Knox Gateway uses 
Apache Shiro (org.apache.shiro.realm.ldap.JndiLdapRealm) to authenticate users 
against the configured LDAP store.

      nameservice = service.use.hdfs_nn[0].options.nameservice
      options.topologies ?= {}
      options.topologies[nameservice] ?= {}
      options.topologies[nameservice].services ?= {}
      options.topologies[nameservice].services['namenode'] ?= !!service.use.hdfs_nn
      options.topologies[nameservice].services['webhdfs'] ?= !!service.use.hdfs_nn
      options.topologies[nameservice].services['jobtracker'] ?= !!service.use.yarn_rm
      options.topologies[nameservice].services['hive'] ?= !!service.use.hive_server2
      options.topologies[nameservice].services['webhcat'] ?= !!service.use.hive_webhcat
      options.topologies[nameservice].services['oozie'] ?= !!service.use.oozie_server
      options.topologies[nameservice].services['webhbase'] ?= !!service.use.hbase_rest
      for nameservice, topology of options.topologies
        # Configure providers
        topology.providers ?= {}
        topology.providers['authentication'].name ?= 'ShiroProvider'
        topology.providers['authentication'].config ?= {}
        topology.providers['authentication'].config['sessionTimeout'] ?= 30
        # By default, we only configure a simple LDAP Binding (user only)
        # migration: wdavidw 170922, this used to be:
        # realms = 'ldapRealm': topology
        realms = 'ldapRealm': {}
        if topology.group
          realms['ldapGroupRealm'] = if topology.group.lookup? then @config.sssd.config[topology.group.lookup] else topology.group
        for realm, realm_config of realms
          topology.providers['authentication'].config["main.#{realm}"] ?= 'org.apache.hadoop.gateway.shirorealm.KnoxLdapRealm' # OpenLDAP implementation
          # topology.providers['authentication'].config['main.ldapRealm'] ?= 'org.apache.shiro.realm.ldap.JndiLdapRealm' # AD implementation
          topology.providers['authentication'].config["main.#{realm}".replace('Realm','')+"ContextFactory"] ?= 'org.apache.hadoop.gateway.shirorealm.KnoxLdapContextFactory'
          topology.providers['authentication'].config["main.#{realm}.contextFactory"] ?= '$'+"#{realm}".replace('Realm','')+'ContextFactory'
          # ctxs = @contexts 'masson/core/openldap_server'
          throw Error 'Required property ldap_uri' unless realm_config['ldap_uri']?
          throw Error 'Required property ldap_default_bind_dn' unless realm_config['ldap_default_bind_dn']?
          throw Error 'Required property ldap_default_authtok' unless realm_config['ldap_default_authtok']?
          throw Error 'Required property ldap_search_base' unless realm_config['ldap_search_base']?
          throw Error 'Required property ldap_search_base' if realm is 'ldapGroupRealm' and not realm_config['ldap_group_search_base']?
          topology.providers['authentication'].config["main.#{realm}.userDnTemplate"] = realm_config['userDnTemplate'] if realm_config['userDnTemplate']?
          topology.providers['authentication'].config["main.#{realm}.contextFactory.url"] = realm_config['ldap_uri'].split(',')[0]
          topology.providers['authentication'].config["main.#{realm}.contextFactory.systemUsername"] = realm_config['ldap_default_bind_dn']
          topology.providers['authentication'].config["main.#{realm}.contextFactory.systemPassword"] = "${ALIAS=#{nameservice}-#{realm}-password}"

          options.realm_passwords["#{nameservice}-#{realm}-password"] = realm_config['ldap_default_authtok']

          topology.providers['authentication'].config["main.#{realm}.searchBase"] = realm_config["ldap#{if realm == 'ldapGroupRealm' then '_group' else ''}_search_base"]
          topology.providers['authentication'].config["main.#{realm}.contextFactory.authenticationMechanism"] ?= 'simple'
          topology.providers['authentication'].config["main.#{realm}.authorizationEnabled"] ?= 'true'
        # we redo the test here, so that these params are rendered at the end of the authentication provider section 
        if topology.group?
          topology.providers['authentication'].config['main.ldapGroupRealm.groupObjectClass'] = topology.group['groupObjectClass'] ?= "posixGroup"
          topology.providers['authentication'].config['main.ldapGroupRealm.memberAttribute'] = topology.group['memberAttribute'] ?= "memberUid"
          topology.providers['authentication'].config['main.ldapGroupRealm.memberAttributeValueTemplate'] = 'uid={0},' + topology['ldap_search_base']
        topology.providers['authentication'].config['urls./**'] ?= 'authcBasic'
        topology.providers['authentication'].config['main.securityManager.realms'] = ["$"+realm for realm, _ of realms].join "," if topology.group?

        # LDAP Authentication Caching
        topology.providers['authentication'].config['main.cacheManager'] = "org.apache.shiro.cache.ehcache.EhCacheManager"
        topology.providers['authentication'].config['main.securityManager.cacheManager'] = "$cacheManager"
        topology.providers['authentication'].config['main.ldapRealm.authenticationCachingEnabled'] = true
        topology.providers['authentication'].config['main.cacheManager.cacheManagerConfigFile'] = "classpath:#{nameservice}-ehcache.xml"

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
          if service.use.hdfs_nn
            topology.services['namenode'] = service.use.hdfs_nn[0].options.core_site['fs.defaultFS']
          else throw Error 'Cannot autoconfigure KNOX namenode service, no namenode declared'  
        if topology.services['webhdfs'] is true
          throw Error 'Cannot autoconfigure KNOX webhdfs service, no namenode declared' unless service.use.hdfs_nn
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
          if service.use.hdfs_nn.length > 1
            topology.providers['ha'] ?= name: 'HaProvider'
            topology.providers['ha'].config ?= {}
            topology.providers['ha'].config['WEBHDFS'] ?= 'maxFailoverAttempts=3;failoverSleep=1000;maxRetryAttempts=300;retrySleep=1000;enabled=true'
            topology.services['webhdfs'] = []
            for srv in service.use.hdfs_nn
              protocol = if srv.options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
              port = srv.options.hdfs_site["dfs.namenode.#{protocol}-address.#{srv.options.nameservice}.#{srv.node.hostname}"].split(':')[1]
              # We ensure that the default active namenode is first in the list !
              action = if srv.node.fqdn is srv.options.active_nn_host then 'unshift' else 'push'
              topology.services['webhdfs'][action] "#{protocol}://#{srv.node.fqdn}:#{port}/webhdfs"
          else
            protocol = if srv.use.hdfs_nn[0].options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
            port = srv.use.hdfs_nn[0].options.hdfs_site["dfs.namenode.#{protocol}-address"].split(':')[1]
            topology.services['webhdfs'] = "#{protocol}://#{srv.use.hdfs_nn[0].node.fqdn}:#{port}/webhdfs" 
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
              if options.config.webhbase?
                topology.services['webhbase'] =
                  url: "#{protocol}://#{host}:#{port}"
                  params: options.config.webhbase
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

      options.log4j ?= {}
      options.log4jopts ?= {}
      options.log4jopts['app.log.dir'] ?= "#{options.log_dir}"
      options.log4jopts['log4j.rootLogger'] ?= 'ERROR,rfa'
      if @config.log4j?.services?
        if @config.log4j?.remote_host? and @config.log4j?.remote_port? and ('ryba/knox' in @config.log4j?.services)
          options.socket_client ?= 'SOCKET'
          # Root logger
          if options.log4jopts['log4j.rootLogger'].indexOf(options.socket_client) is -1
          then options.log4jopts['log4j.rootLogger'] += ",#{options.socket_client}"
          # Set java opts
          options.log4jopts['app.log.application'] ?= 'knox'
          options.log4jopts['app.log.remote_host'] ?= @config.log4j.remote_host
          options.log4jopts['app.log.remote_port'] ?= @config.log4j.remote_port
          options.socket_opts ?=
            Application: '${app.log.application}'
            RemoteHost: '${app.log.remote_host}'
            Port: '${app.log.remote_port}'
            ReconnectionDelay: '10000'
          options.log4j = merge options.log4j, appender
            type: 'org.apache.log4j.net.SocketAppender'
            name: options.socket_client
            logj4: options.log4j
            properties: options.socket_opts

## Dependencies

    appender = require '../lib/appender'
    {merge} = require 'nikita/lib/misc'
