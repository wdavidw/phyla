
# Hue Configure

*   `hdp.hue.ini.desktop.database.admin_username` (string)
    Database admin username used to create the Hue database user.
*   `hdp.hue.ini.desktop.database.admin_password` (string)
    Database admin password used to create the Hue database user.
*   `hue.ini`
    Configuration merged with default values and written to "/etc/hue/conf/hue.ini" file.
*   `hue.user` (object|string)
    The Unix Hue login name or a user object (see Nikita User documentation).
*   `hue.group` (object|string)
    The Unix Hue group name or a group object (see Nikita Group documentation).

Example:

```json
{
  "ryba": {
    "hue: {
      "user": {
        "name": "hue", "system": true, "gid": "hue",
        "comment": "Hue User", "home": "/usr/lib/hue"
      },
      "group": {
        "name": "Hue", "system": true
      },
      "ini": {
        "desktop": {
          "database":
            "engine": "mysql"
            "password": "hue123"
          "custom": {
            banner_top_html: "HADOOP : PROD"
          }
        }
      },
      banner_style: 'color:white;text-align:center;background-color:red;',
      clean_tmp: false
    }
  }
}
```

    module.exports = ({deps, options, node})->

## Environment

      options.conf_dir ?= '/usr/share/hue/desktop/conf'
      options.log_dir ?= '/var/log/hue'
      options.clean_tmp ?= true

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'hue'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.comment ?= 'Hue User'
      options.user.gid = options.group.name
      options.user.home = '/var/lib/hue'
      options.user.name ?= 'hue'
      options.user.system ?= true

## Database

      options.supported_db_engines ?= ['mysql', 'mariadb', 'postgresql']
      options.db ?= {}
      options.db.engine ?= deps.db_admin.options.engine
      Error "Unsupported Database Engine: got #{options.db.engine}" unless options.db.engine in options.supported_db_engines
      options.db = merge deps.db_admin.options[options.db.engine], options.db
      options.db.database ?= 'hue'
      options.db.username ?= 'hue'
      # options.db.jdbc += "/#{options.db.database}?createDatabaseIfNotExist=true"
      throw Error "Required Option: db.password" unless options.db?.password

## Kerberos

      options.krb5 ?= {}
      if deps.krb5_client
        options.krb5.realm ?= deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
        throw Error 'Required Options: "realm"' unless options.krb5.realm
        options.krb5.admin ?= deps.krb5_client.options.admin[options.krb5.realm]

## Proxy Users

      # hadoop_ctxs = @contexts ['@rybajs/metal/hadoop/hdfs_nn', '@rybajs/metal/hadoop/hdfs_dn', '@rybajs/metal/hadoop/yarn_rm', '@rybajs/metal/hadoop/yarn_nm']
      # for hadoop_ctx in hadoop_ctxs
      #   hadoop_ctx.config.ryba ?= {}
      #   hadoop_ctx.config.ryba.core_site ?= {}
      #   hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{options.user.name}.hosts"] ?= '*'
      #   hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{options.user.name}.groups"] ?= '*'
      # httpfs_ctxs = @contexts '@rybajs/metal/hadoop/httpfs'
      # for httpfs_ctx in httpfs_ctxs
      #   httpfs_ctx.config.ryba ?= {}
      #   httpfs_ctx.config.ryba.httpfs ?= {}
      #   httpfs_ctx.config.ryba.httpfs.site ?= {}
      #   httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{options.user.name}.hosts"] ?= '*'
      #   httpfs_ctx.config.ryba.httpfs.site["httpfs.proxyuser.#{options.user.name}.groups"] ?= '*'
      # oozie_ctxs = @contexts '@rybajs/metal/oozie/server'
      # for oozie_ctx in oozie_ctxs
      #   oozie_ctx.config.ryba ?= {}
      #   oozie_ctx.config.ryba.oozie ?= {}
      #   oozie_ctx.config.ryba.oozie.site ?= {}
      #   oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.hosts"] ?= '*'
      #   oozie_ctx.config.ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.groups"] ?= '*'
      # {hadoop_conf_dir, webhcat, hue, db_admin, core_site, hdfs, yarn} = ryba
      # nn_ctxs = @contexts '@rybajs/metal/hadoop/hdfs_nn', require('../hadoop/hdfs_nn/configure').handler

## Configuration

      options.ini ?= {}
      # # todo, this might not work as expected after ha migration
      # # nodemanagers = @contexts('@rybajs/metal/hadoop/yarn_nm').map((ctx) -> ctx.config.host)
      # # Webhdfs should be active on the NameNode, Secondary NameNode, and all the DataNodes
      # # throw new Error 'WebHDFS not active' if ryba.hdfs.site['dfs.webhdfs.enabled'] isnt 'true'
      # options.ca_bundle ?= '/etc/hue/conf/trust.pem'
      # options.ssl ?= {}
      # options.ssl.client_ca ?= null
      # throw Error "Property 'hue.ssl.client_ca' required in HA with HTTPS" if nn_ctxs.length > 1 and ryba.hdfs.site['dfs.http.policy'] is 'HTTPS_ONLY' and not options.ssl.client_ca
      # # HDFS & YARN url
      # # NOTE: default to unencrypted HTTP
      # # error is "SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed"
      # # see https://github.com/cloudera/hue/blob/master/docs/manual.txt#L433-L439
      # # another solution could be to set REQUESTS_CA_BUNDLE but this isnt tested
      # # see http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cm_sg_ssl_hue.html
      # # Hue Install defines a dependency on HDFS client
      # nn_protocol = if nn_ctxs[0].config.ryba.hdfs.nn.site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      # nn_protocol = 'http' if nn_ctxs[0].config.ryba.hdfs.nn.site['dfs.http.policy'] is 'HTTP_AND_HTTPS' and not hue.ssl_client_ca
      # if nn_ctxs[0].config.ryba.hdfs.nn.site['dfs.ha.automatic-failover.enabled'] is 'true'
      #   nn_host = nn_ctxs[0].config.ryba.active_nn_host
      #   shortname = @contexts(hosts: nn_host)[0].config.shortname
      #   nn_http_port = nn_ctxs[0].config.ryba.hdfs.nn.site["dfs.namenode.#{nn_protocol}-address.#{nn_ctxs[0].config.ryba.nameservice}.#{shortname}"].split(':')[1]
      #   webhdfs_url = "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"
      # else
      #   nn_host = nn_ctxs[0].config.host
      #   nn_http_port = nn_ctxs[0].config.ryba.hdfs.nn.site["dfs.namenode.#{nn_protocol}-address"].split(':')[1]
      #   webhdfs_url = "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"
      # # Support for RM HA was added in Hue 3.7
      # # rm_protocol = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      # # rm_hosts = @contexts('@rybajs/metal/hadoop/yarn_rm').map((ctx) -> ctx.config.host)
      # # if rm_hosts.length > 1
      # #   rm_host = ryba.yarn.active_rm_host
      # #   rm_ctx = @context rm_host, require('../hadoop/yarn_rm').configure
      # #   rm_port = rm_ctx.config.ryba.yarn.site["yarn.resourcemanager.address.#{rm_ctx.config.shortname}"].split(':')[1]
      # #   yarn_api_url = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
      # #   then "http://#{yarn.site['yarn.resourcemanager.webapp.address.#{rm_ctx.config.shortname}']}"
      # #   else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address.#{rm_ctx.config.shortname}']}"
      # # else
      # #   rm_host = rm_hosts[0]
      # #   rm_ctx = @context rm_host, require('../hadoop/yarn_rm').configure
      # #   rm_port = rm_ctx.config.ryba.yarn.site['yarn.resourcemanager.address'].split(':')[1]
      # #   yarn_api_url = if yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
      # #   then "http://#{yarn.site['yarn.resourcemanager.webapp.address']}"
      # #   else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address']}"
      # # YARN ResourceManager
      # rm_ctxs = @contexts '@rybajs/metal/hadoop/yarn_rm', require('../hadoop/yarn_rm/configure').handler
      # throw Error "No YARN ResourceManager configured" unless rm_ctxs.length
      # is_yarn_ha = rm_ctxs.length > 1
      # rm_ctx = rm_ctxs[0]
      # yarn_id = if rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.enabled'] is 'true' then ".#{rm_ctx.config.ryba.yarn.rm.site['yarn.resourcemanager.ha.id']}" else ''
      # rm_host = rm_ctx.config.host
      # # Strange, "rm_rpc_url" default to "http://localhost:8050" which doesnt make
      # # any sense since this isnt http
      # rm_rpc_add = rm_ctx.config.ryba.yarn.rm.site["yarn.resourcemanager.address#{yarn_id}"]
      # rm_rpc_url = "http://#{rm_rpc_add}"
      # rm_port = rm_rpc_add.split(':')[1]
      # yarn_api_url = if rm_ctx.config.ryba.yarn.rm.site['yarn.http.policy'] is 'HTTP_ONLY'
      # then "http://#{yarn.site['yarn.resourcemanager.webapp.address']}"
      # else "https://#{yarn.site['yarn.resourcemanager.webapp.https.address']}"
      # # NodeManager
      # [nm_ctx] = @contexts '@rybajs/metal/hadoop/yarn_nm', require('../hadoop/yarn_nm/configure').handler
      # node_manager_api_url = if @config.ryba.yarn.site['yarn.http.policy'] is 'HTTP_ONLY'
      # then "http://#{nm_ctx.config.ryba.yarn.site['yarn.nodemanager.webapp.address']}"
      # else "https://#{nm_ctx.config.ryba.yarn.site['yarn.nodemanager.webapp.https.address']}"
      # # WebHcat
      # [webhcat_ctx] = @contexts '@rybajs/metal/hive/webhcat', require('../hive/webhcat/configure').handler
      # if webhcat_ctx
      #   webhcat_port = webhcat_ctx.config.ryba.webhcat.site['templeton.port']
      #   templeton_url = "http://#{webhcat_ctx.config.host}:#{webhcat_port}/templeton/v1/"
      # # Configure HDFS Cluster
      # hue.ini['hadoop'] ?= {}
      # hue.ini['hadoop']['hdfs_clusters'] ?= {}
      # hue.ini['hadoop']['hdfs_clusters']['default'] ?= {}
      # # HA require webhdfs_url
      # hue.ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= core_site['fs.defaultFS']
      # hue.ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= webhdfs_url
      # hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_hdfs_home'] ?= '/usr/lib/hadoop'
      # hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      # hue.ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      # # Configure YARN (MR2) Cluster
      # hue.ini['hadoop']['yarn_clusters'] ?= {}
      # hue.ini['hadoop']['yarn_clusters']['default'] ?= {}
      # hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_host'] ?= "#{rm_host}" # Might no longer be required after hdp2.2
      # hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_port'] ?= "#{rm_port}" # Might no longer be required after hdp2.2
      # hue.ini['hadoop']['yarn_clusters']['default']['submit_to'] ?= "true"
      # hue.ini['hadoop']['yarn_clusters']['default']['hadoop_mapred_home'] ?= '/usr/hdp/current/hadoop-mapreduce-client'
      # hue.ini['hadoop']['yarn_clusters']['default']['hadoop_bin'] ?= '/usr/hdp/current/hadoop-client/bin/hadoop'
      # hue.ini['hadoop']['yarn_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
      # hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_api_url'] ?= yarn_api_url
      # hue.ini['hadoop']['yarn_clusters']['default']['resourcemanager_rpc_url'] ?= rm_rpc_url
      # hue.ini['hadoop']['yarn_clusters']['default']['proxy_api_url'] ?= yarn_api_url
      # hue.ini['hadoop']['yarn_clusters']['default']['node_manager_api_url'] ?= node_manager_api_url
      # # JHS
      # [jhs_ctx] = @contexts '@rybajs/metal/hadoop/mapred_jhs', require('../hadoop/mapred_jhs/configure').handler
      # jhs_protocol = if jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.http.policy'] is 'HTTP' then 'http' else 'https'
      # jhs_port = if jhs_protocol is 'http'
      # then jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      # else jhs_ctx.config.ryba.mapred.site['mapreduce.jobhistory.webapp.https.address'].split(':')[1]
      # hue.ini['hadoop']['yarn_clusters']['default']['history_server_api_url'] ?= "#{jhs_protocol}://#{jhs_ctx.config.host}:#{jhs_port}"
      # # Configure components
      # hue.ini['liboozie'] ?= {}
      # hue.ini['liboozie']['oozie_url'] ?= ryba.oozie.site['oozie.base.url']
      # hue.ini['hcatalog'] ?= {}
      # hue.ini['hcatalog']['templeton_url'] ?= templeton_url
      # hue.ini['beeswax'] ?= {}
      # # HCatalog
      # [hs2_ctx] = @contexts '@rybajs/metal/hive/server2', require('../hive/server2/configure').handler
      # throw Error "No Hive HCatalog Server configured" unless hs2_ctx
      # hue.ini['beeswax']['hive_server_host'] ?= "#{hs2_ctx.config.host}"
      # hue.ini['beeswax']['hive_server_port'] ?= if hs2_ctx.config.ryba.hive.site['hive.server2.transport.mode'] is 'binary'
      # then hs2_ctx.config.ryba.hive.site['hive.server2.thrift.port']
      # else hs2_ctx.config.ryba.hive.site['hive.server2.thrift.http.port']
      # # http://www.cloudera.com/content/www/en-us/documentation/cdh/5-0-x/CDH5-Security-Guide/cdh5sg_hue_security.html
      # if hs2_ctx.config.ryba.hive.site['hive.server2.use.SSL']
      #   throw Error 'Hue must be configured with ssl if communicating with hive over ssl' unless  hue.ssl.client_ca
      #   hue.ini['beeswax']['ssl'] ?= {}
      #   hue.ini['beeswax']['ssl']['enabled'] ?= 'true'
      #   hue.ini['beeswax']['ssl']['cacerts'] ?= "#{hue.conf_dir}/trust.pem"
      #   hue.ini['beeswax']['ssl']['cert'] ?= "#{hue.conf_dir}/cert.pem"
      #   hue.ini['beeswax']['ssl']['key'] ?= "#{hue.conf_dir}/key.pem"
      # # Desktop
      options.ini['desktop'] ?= {}
      options.ini['desktop']['app_blacklist'] ?= 'rdbms,impala,sqoop,sentry,search,solr,spark,zookeeper,security,hbase'
      # hue.ini['desktop']['django_debug_mode'] ?= '0' # Disable debug by default
      # hue.ini['desktop']['http_500_debug_mode'] ?= '0' # Disable debug by default
      # hue.ini['desktop']['http'] ?= {}
      # hue.ini['desktop']['http_host'] ?= '0.0.0.0'
      options.ini['desktop']['http_port'] ?= '8888'
      throw Error "Required Option: hue.ini.desktop.secret_key" unless options.ini['desktop']['secret_key']
      # hue.ini['desktop']['smtp'] ?= {}
      options.ini['desktop']['time_zone'] ?= 'Etc/UCT'
      # # Desktop database
      options.ini['desktop']['database'] ?= {}
      options.ini['desktop']['database']['engine'] ?= options.db.engine
      options.ini['desktop']['database']['engine'] = 'mysql' if options.ini['desktop']['database']['engine'] is 'mariadb'
      options.ini['desktop']['database']['host'] ?= options.db.host
      options.ini['desktop']['database']['port'] ?= options.db.port
      options.ini['desktop']['database']['user'] ?= options.db.username
      options.ini['desktop']['database']['password'] ?= options.db.password
      options.ini['desktop']['database']['name'] ?= options.db.database
      # SSL
      options.ini['desktop']['ssl_certificate'] ?= path.join options.conf_dir , 'cert.pem'
      options.ini['desktop']['ssl_private_key'] ?= path.join options.conf_dir , 'key.pem'
      options.ini['desktop']['ssl_cacerts'] ?= path.join options.conf_dir , 'ca.crt'
      # Kerberos
      options.ini.desktop.kerberos ?= {}
      options.ini.desktop.kerberos.hue_keytab ?= '/etc/hue/conf/hue.service.keytab'
      options.ini.desktop.kerberos.hue_principal ?= "hue/#{node.fqdn}@#{deps.ipa_client.options.realm_name}"
      # # Path to kinitdeps.ipa_server
      # # For RHEL/CentOS 5.x, kinit_path is /usr/kerberos/bin/kinit
      # # For RHEL/CentOS 6.x, kinit_path is /usr/bin/kinit
      options.ini.desktop.kerberos.kinit_path ?= '/usr/bin/kinit'
      # It does work without this
      # options.ini.desktop.kerberos.ccache_path ?= "/tmp/krb5cc_0"
      # # Uncomment all security_enabled settings and set them to true
      # HDFS
      options.ini.hadoop ?= {}
      options.ini.hadoop.hdfs_clusters ?= {}
      options.ini.hadoop.hdfs_clusters.default ?= {}
      options.ini.hadoop.hdfs_clusters.default.security_enabled = 'true'
      # hue.ini.hadoop.mapred_clusters ?= {}
      # hue.ini.hadoop.mapred_clusters.default ?= {}
      # hue.ini.hadoop.mapred_clusters.default.security_enabled = 'true'
      # YARN
      options.ini.hadoop.yarn_clusters ?= {}
      options.ini.hadoop.yarn_clusters.default ?= {}
      options.ini.hadoop.yarn_clusters.default.security_enabled = 'true'
      options.ini.hadoop.yarn_clusters.default.submit_to = 'True'
      # OOZIE
      options.ini.liboozie ?= {}
      options.ini.liboozie.security_enabled ?= 'true'
      # HIVE
      options.ini.beeswax ?= {}
      options.ini.beeswax.hive_conf_dir ?= '/etc/hive/conf'
      options.ini.beeswax.server_conn_timeout ?= 240
      options.ini.beeswax.max_number_of_sessions ?= 1
      

## Wait

      options.wait_db_admin = deps.db_admin.options.wait

## Dependencies

    path = require 'path'
    {merge} = require 'mixme'
