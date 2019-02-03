
## Configure

*   `hdp.hue_docker.ini.desktop.database.admin_username` (string)
    Database admin username used to create the Hue database user.
*   `options.ini.desktop.database.admin_password` (string)
    Database admin password used to create the Hue database user.
*   `options.ini`
    Configuration merged with default values and written to "/etc/hue/conf/hue_docker.ini" file.
*   `options.user` (object|string)
    The Unix Hue login name or a user object (see Nikita User documentation).
*   `options.group` (object|string)
    The Unix Hue group name or a group object (see Nikita Group documentation).

Example:

```json
{ "ryba": { "hue: {
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
        "engine": "mysql",
        "password": "Hue123-"
      "custom": {
        "banner_top_html": "HADOOP : PROD"
      }
    }
  },
  banner_style: 'color:white;text-align:center;background-color:red;',
  clean_tmp: false
} } }
```

[hbase-configuration]:(http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/)

    module.exports = (service) ->
      options = service.options

## Environment

      options.cache_dir ?= './cache'
      # Layout
      options.conf_dir ?= '/etc/hue-docker/conf'
      options.log_dir ?= '/var/log/hue-docker'
      options.pid_file ?= '/var/run/hue-docker'
      # Production container image name
      options.version ?= '4.1.0'
      options.image ?= 'ryba/hue'
      options.container ?= 'hue_server'
      # Huedocker service name has to match nagios hue_docker_check_status.sh file in ryba/nagios/resources/plugins
      options.service ?= 'hue-server-docker'
      options.build ?= {}
      options.build.source ?= 'https://github.com/cloudera/hue.git'
      options.build.name ?= 'ryba/hue-build'
      options.build.version ?= 'latest'
      options.build.dockerfile ?= "#{__dirname}/resources/build/Dockerfile_#{options.version}"
      options.build.directory ?= "#{options.cache_dir}/huedocker/build" # was '/tmp/ryba/hue-build'
      options.prod ?= {}
      options.prod.directory ?= "#{options.cache_dir}/huedocker/prod"
      options.prod.dockerfile ?= "#{__dirname}/resources/prod/Dockerfile"
      options.prod.tar ?= 'hue_docker.tar'
      options.port ?= '8888'
      options.image_dir ?= '/tmp'
      options.clean_tmp ?= true
      blacklisted_app = []

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'hue'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'hue'
      options.user.gid ?= options.group.name
      options.user.system ?= true
      options.user.comment ?= 'Hue User'
      options.user.home = '/var/lib/hue_docker' # TODO: shall be "/var/lib/hue" to not conflict with hue service


      options.fqdn = service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]

## Configuration

      options.ini ?= {}
      # Webhdfs should be active on the NameNode, Secondary NameNode, and all the DataNodes
      # throw new Error 'WebHDFS not active' if ryba.hdfs.site['dfs.webhdfs.enabled'] isnt 'true'
      options.ca_bundle ?= "#{options.conf_dir}/cacert.pem"

## Hue Webui TLS

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      if options.ssl.enabled
        throw Error "Required Option: ssl.cacert" if options.ssl and not options.ssl.cacert
        throw Error "Required Option: ssl.cert" if options.ssl and not options.ssl.cert
        throw Error "Required Option: ssl.key" if options.ssl and not options.ssl.key
      # HDFS & YARN url
      # NOTE: default to unencrypted HTTP
      # error is "SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed"
      # see https://github.com/cloudera/hue/blob/master/docs/manual.txt#L433-L439
      # another solution could be to set REQUESTS_CA_BUNDLE but this isnt tested
      # see http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cm_sg_ssl_hue.html

      options.ini['hadoop'] ?= {}
      # For HDFS HA deployments,  HttpFS is preferred over webhdfs.It should be installed

      if service.deps.httpfs
        httpfs_protocol = if service.deps.httpfs[0].options.env.HTTPFS_SSL_ENABLED then 'https' else 'http'
        httpfs_port = service.deps.httpfs[0].options.http_port
        webhdfs_url = "#{httpfs_protocol}://#{service.deps.httpfs[0].node.fqdn}:#{httpfs_port}/webhdfs/v1"
      else
        # Hue Install defines a dependency on HDFS client
        nn_protocol = if service.deps.hdfs_nn[0].options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
        nn_protocol = 'http' if service.deps.hdfs_nn[0].options.hdfs_site['dfs.http.policy'] is 'HTTP' # _AND_HTTPS and not hue.ssl?.cacert
        if service.deps.hdfs_nn[0].options.hdfs_site['dfs.ha.automatic-failover.enabled'] is 'true'
          nn_host = service.deps.hdfs_nn[0].options.active_nn_host
          shortname = service.deps.hdfs_nn[0].node.hostname
          nn_http_port = service.deps.hdfs_nn[0].options.hdfs_site["dfs.namenode.#{nn_protocol}-address.#{service.deps.hdfs_nn[0].options.nameservice}.#{shortname}"].split(':')[1]
          webhdfs_url = "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"
        else
          nn_host = service.deps.hdfs_nn[0].node.fqdn
          nn_http_port = service.deps.hdfs_nn[0].options.hdfs_site["dfs.namenode.#{nn_protocol}-address"].split(':')[1]
          webhdfs_url = "#{nn_protocol}://#{nn_host}:#{nn_http_port}/webhdfs/v1"

      # YARN ResourceManager (MR2 Cluster)
      options.ini['hadoop']['yarn_clusters'] = {}
      options.ini['hadoop']['yarn_clusters']['default'] ?= {}
      rm_hosts = service.deps.yarn_rm.map( (srv) -> srv.node.fqdn)
      rm_host = if rm_hosts.length > 1 then service.deps.yarn_rm[0].options.active_rm_host else rm_hosts[0]
      throw Error "No YARN ResourceManager configured" unless service.deps.yarn_rm.length
      yarn_api_url = []
      # Support for RM HA was added in Hue 3.7
      if rm_hosts.length > 1
        # Active RM
        rm_port = service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.address.#{service.deps.yarn_rm[0].node.hostname}"].split(':')[1]
        yarn_api_url[0] = if service.deps.yarn_rm[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.http.address.#{service.deps.yarn_rm[0].node.hostname}"]}"
        else "https://#{service.deps.yarn_rm[0].options.yarn_site["yarn.resourcemanager.webapp.https.address.#{service.deps.yarn_rm[0].node.hostname}"]}"

        # Standby RM
        rm_port_ha = service.deps.yarn_rm[1].options.yarn_site["yarn.resourcemanager.address.#{service.deps.yarn_rm[0].node.hostname}"].split(':')[1]
        yarn_api_url[1] = if service.deps.yarn_rm[1].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{service.deps.yarn_rm[1].options.yarn_site["yarn.resourcemanager.webapp.http.address.#{service.deps.yarn_rm[0].node.hostname}"]}"
        else "https://#{service.deps.yarn_rm[1].options.yarn_site["yarn.resourcemanager.webapp.https.address.#{service.deps.yarn_rm[0].node.hostname}"]}"

        # options.ini['hadoop']['yarn_clusters']['default']['logical_name'] ?= "#{yarn.site['yarn.resourcemanager.cluster-id']}"
        options.ini['hadoop']['yarn_clusters']['default']['logical_name'] ?= "#{service.deps.yarn_rm[0].node.hostname}"

        # The [[ha]] section contains the 2nd YARN_RM information when HA is enabled
        options.ini['hadoop']['yarn_clusters']['ha'] ?= {}
        options.ini['hadoop']['yarn_clusters']['ha']['submit_to'] ?= "true"
        options.ini['hadoop']['yarn_clusters']['ha']['resourcemanager_api_url'] ?= "#{yarn_api_url[1]}"
        # options.ini['hadoop']['yarn_clusters']['ha']['resourcemanager_port'] ?= "#{rm_port_ha}"
        options.ini['hadoop']['yarn_clusters']['ha']['logical_name'] ?= "#{service.deps.yarn_rm[1].node.hostname}"
        # options.ini['hadoop']['yarn_clusters']['ha']['logical_name'] ?= "#{yarn.site['yarn.resourcemanager.cluster-id']}"
      else
        rm_port = service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.address'].split(':')[1]
        yarn_api_url[0] = if service.deps.yarn_rm[0].options.yarn_site['yarn.http.policy'] is 'HTTP_ONLY'
        then "http://#{service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.webapp.http.address']}"
        else "https://#{service.deps.yarn_rm[0].options.yarn_site['yarn.resourcemanager.webapp.https.address']}"

      options.ini['hadoop']['yarn_clusters']['default']['submit_to'] ?= "true"
      # options.ini['hadoop']['yarn_clusters']['default']['resourcemanager_host'] ?= "#{rm_host}"
      # options.ini['hadoop']['yarn_clusters']['default']['resourcemanager_port'] ?= "#{rm_port}"
      options.ini['hadoop']['yarn_clusters']['default']['resourcemanager_api_url'] ?= "#{yarn_api_url[0]}"
      options.ini['hadoop']['yarn_clusters']['default']['hadoop_mapred_home'] ?= '/usr/hdp/current/hadoop-mapreduce-client'

      # Configure HDFS Cluster
      options.ini['hadoop']['hdfs_clusters'] ?= {}
      options.ini['hadoop']['hdfs_clusters']['default'] ?= {}
      # HA require webhdfs_url
      options.ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= service.deps.hdfs_nn[0].options.core_site['fs.defaultFS']
      options.ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= webhdfs_url
      options.ini['hadoop']['hdfs_clusters']['default']['hadoop_hdfs_home'] ?= '/usr/lib/hadoop'
      options.ini['hadoop']['hdfs_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
      options.ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir'] ?= service.deps.hadoop_core.options.conf_dir
      # JobHistoryServer
      jhs_protocol = if service.deps.mapred_jhs[0].options.mapred_site['mapreduce.jobhistory.http.policy'] is 'HTTP' then 'http' else 'https'
      jhs_port = if jhs_protocol is 'http'
      then service.deps.mapred_jhs[0].options.mapred_site['mapreduce.jobhistory.webapp.address'].split(':')[1]
      else service.deps.mapred_jhs[0].options.mapred_site['mapreduce.jobhistory.webapp.https.address'].split(':')[1]
      options.ini['hadoop']['yarn_clusters']['default']['history_server_api_url'] ?= "#{jhs_protocol}://#{service.deps.mapred_jhs[0].node.fqdn}:#{jhs_port}"

      # Oozie
      if service.deps.oozie_server
        options.ini['liboozie'] ?= {}
        options.ini['liboozie']['security_enabled'] ?= 'true'
        options.ini['liboozie']['oozie_url'] ?= service.deps.oozie_server[0].options.oozie_site['oozie.base.url']
      else
        blacklisted_app.push 'oozie'
      # WebHcat
      if service.deps.hive_webhcat
        webhcat_port = service.deps.hive_webhcat[0].options.webhcat_site['templeton.port']
        templeton_url = "http://#{service.deps.hive_webhcat[0].node.fqdn}:#{webhcat_port}/templeton/v1/"
        options.ini['hcatalog'] ?= {}
        options.ini['hcatalog']['templeton_url'] ?= templeton_url
        options.ini['beeswax'] ?= {}
      if service.deps.hive_webhcat.length
        for srv in service.deps.hive_webhcat
          srv.options.webhcat_site["webhcat.proxyuser.#{options.user.name}.users"] ?= '*'
          srv.options.webhcat_site["webhcat.proxyuser.#{options.user.name}.groups"] ?= '*'
      else
        blacklisted_app.push 'webhcat'

      # HiveServer2
      throw Error "No Hive HCatalog Server configured" unless service.deps.hive_server2
      options.ini['beeswax'] ?= {}
      options.ini['beeswax']['hive_server_host'] ?= "#{service.deps.hive_server2[0].node.fqdn}"
      options.ini['beeswax']['hive_server_port'] ?= if service.deps.hive_server2[0].options.hive_site['hive.server2.transport.mode'] is 'binary'
      then service.deps.hive_server2[0].options.hive_site['hive.server2.thrift.port']
      else service.deps.hive_server2[0].options.hive_site['hive.server2.thrift.http.port']
      options.ini['beeswax']['hive_conf_dir'] ?= '/etc/hive/conf' # Hive client is a dependency of Hue
      options.ini['beeswax']['server_conn_timeout'] ?= "240"
      # Desktop
      options.ini['desktop'] ?= {}
      options.ini['desktop']['django_debug_mode'] ?= '0' # Disable debug by default
      options.ini['desktop']['http_500_debug_mode'] ?= '0' # Disable debug by default
      options.ini['desktop']['http'] ?= {}
      options.ini['desktop']['http_host'] ?= '0.0.0.0'
      options.ini['desktop']['http_port'] ?= options.port
      options.ini['desktop']['secret_key'] ?= 'jFE93j;2[290-eiwMYSECRTEKEYy#e=+Iei*@Mn<qW5o'
      options.ini['desktop']['ssl_certificate'] ?= if options.ssl.enabled then "#{options.conf_dir}/cert.pem"else null
      options.ini['desktop']['ssl_private_key'] ?= if options.ssl.enabled then "#{options.conf_dir}/key.pem" else null
      options.ini['desktop']['smtp'] ?= {}
      # From Hue 3.7 ETC has become Etc
      options.ini['desktop']['time_zone'] ?= 'Etc/UCT'

## Desktop database

      options.db ?= {}
      options.db.engine ?= service.deps.db_admin.options.engine
      options.db = merge {}, service.deps.db_admin.options[options.db.engine], options.db
      options.db.database ?= 'hue3'
      options.db.username ?= 'hue'
      throw Error "Required Option: db.password" unless options.db.password
      options.ini['desktop']['database'] ?= {}
      options.ini['desktop']['database']['engine'] = 'mysql' if options.db.engine in ['mariadb', 'mysql']
      options.ini['desktop']['database']['engine'] = 'postgresql' if options.db.engine is 'postgresql'
      options.ini['desktop']['database']['engine'] ?= 'derby'
      options.ini['desktop']['database']['host'] ?= options.db.host
      options.ini['desktop']['database']['port'] ?= options.db.port
      options.ini['desktop']['database']['user'] ?= options.db.username
      options.ini['desktop']['database']['password'] ?= options.db.password
      options.ini['desktop']['database']['name'] ?= options.db.database
      # Kerberos
      options.ini.desktop.kerberos ?= {}
      options.ini.desktop.kerberos.hue_keytab ?= "#{options.conf_dir}/hue.service.keytab" # was /etc/hue/conf/hue.server.keytab
      options.ini.desktop.kerberos.hue_principal ?= "#{options.user.name}/#{service.node.fqdn}@#{options.krb5.realm}" # was hue_docker/#{ctx.config.host}@#{ryba.realm}
      # Path to kinit
      # For RHEL/CentOS 5.x, kinit_path is /usr/kerberos/bin/kinit
      # For RHEL/CentOS 6.x, kinit_path is /usr/bin/kinit
      options.ini['desktop']['kerberos']['kinit_path'] ?= '/usr/bin/kinit'
      # setting cache_name
      options.ini['desktop']['kerberos']['ccache_path'] ?= "/tmp/krb5cc_#{options.user.uid}"
      # Remove unused module
      blacklisted_app.push 'rdbms'
      blacklisted_app.push 'impala'
      blacklisted_app.push 'sqoop'
      blacklisted_app.push 'sentry'
      blacklisted_app.push 'search'
      blacklisted_app.push 'solr'
      # Sqoop
      sqoop_hosts = service.deps.sqoop.map( (srv) -> srv.node.fqdn)

      # HBase
      # Configuration for Hue version > 3.8.1 (July 2015)
      # Hue communicates with hbase throught the thrift server from Hue 3.7 version
      # Hbase has to be configured to offer impersonation
      # http://gethue.com/hbase-browsing-with-doas-impersonation-and-kerberos/
      if service.deps.hbase_thrift.length
        hbase_thrift_cluster = ''
        for key, srv of service.deps.hbase_thrift
          host_adress = ''
          # from source code the hostname should be prefixed with https to warn hue that SSL is enabled
          # activating ssl make hue mismatch fully qualified hostname
          # for now not prefixing anything
          # host_adress += 'https' if hbase_ctx.config.ryba.hbase.thrift.hbase_site['hbase.thrift.ssl.enabled'] and hbase_ctx.config.ryba.hbase.thrift.hbase_site['hbase.regionserver.thrift.http']
          host_adress += '' if srv.options.hbase_site['hbase.thrift.ssl.enabled'] and srv.options.hbase_site['hbase.regionserver.thrift.http']
          host_adress += "#{srv.node.fqdn}:#{srv.options.hbase_site['hbase.thrift.port']}"
          hbase_thrift_cluster +=  if key == '0' then "(Cluster|#{host_adress})" else ",(Cluster|https://#{host_adress})"
        options.ini['hbase'] ?= {}
        options.ini['hbase']['hbase_conf_dir'] ?= service.deps.hbase_client.options.conf_dir
        # Enrich hbase client site with thrift related properties. needed for hbase to
        #communicate with hbase correctly
        for prop in [
          'hbase.thrift.port'
          'hbase.thrift.info.port'
          'hbase.thrift.support.proxyuser'
          'hbase.thrift.security.qop'
          'hbase.thrift.authentication.type'
          'hbase.thrift.kerberos.principal'
          'hbase.thrift.ssl.enabled'
          ]
        then service.deps.hbase_client.options.hbase_site[prop] ?= service.deps.hbase_thrift[0].options.hbase_site[prop]
        options.ini['hbase']['hbase_clusters'] ?= hbase_thrift_cluster
        # Hard limit of rows or columns per row fetched before truncating.
        options.ini['hbase']['truncate_limit'] ?= '500'
        # use_doas says that HBASE THRIFT uses http in order to enable impersonation
        # set to false if you want to unable
        # not stable
        # force the use of impersonation in hue.ini, it can be read by hue if set inside hbase-site.xml file
        options.ini['hbase']['use_doas'] = if service.deps.hbase_thrift[0].options.hbase_site['hbase.regionserver.thrift.http'] then 'true' else 'false'
        options.ini['hbase']['thrift_transport'] =  service.deps.hbase_thrift[0].options.hbase_site['hbase.regionserver.thrift.framed']
      else
        blacklisted_app.push 'hbase'

      # Spark 
      # For now Hue does not support livy on kerberized cluster and ssl protocol
      blacklisted_app.push 'spark'
      # if sls_ctx? and sts_ctx?
      #   {hive_site} = sts_ctx.config.ryba.spark.thrift
      #   port = if hive_site['hive.server2.transport.mode'] is 'http'
      #   then hive_site['hive.server2.thrift.http.port']
      #   else hive_site['hive.server2.thrift.port']
      #   # 
      #   options.ini['spark'] ?= {}
      #   options.ini['spark']['livy_server_host'] ?= sls_ctx.config.host
      #   options.ini['spark']['livy_server_port'] ?= sls_ctx.config.ryba.spark.livy.conf['livy.server.port']
      #   options.ini['spark']['livy_server_session_kind'] ?= 'yarn'
      #   options.ini['spark']['sql_server_host'] ?= sts_ctx.config.host
      #   options.ini['spark']['sql_server_port'] ?= port
      #   if shs_ctx?
      #     options.ini['hadoop']['yarn_clusters']['default']['spark_history_server_url'] ?= "http://#{shs_ctx.config.host}:#{shs_ctx.config.ryba.spark.history.conf['spark.history.ui.port']}"
      # else 
      #   blacklisted_app.push 'spark'

      # Zookeeper
      # for now we do not support zookeeper rest interface
      # zookeeper_ctxs = ctx.contexts ['ryba/zookeeper/server']
      # if zookeeper_ctxs.length
      #   zookeeper_hosts = ''
      #   zookeeper_hosts += ( if key == 0 then "#{zk_ctx.config.host}:#{zk_ctx.config.r}" else ",#{zk_ctx.config.host}:#{zk_ctx.port}") for zk_ctx, key  in zookeeper_ctxs
      # options.ini['clusters']['default']['host_ports'] ?= zookeeper_hosts
      # options.ini['clusters']['default']['rest_url'] ?= 'http://example:port'
      # else
      #   blacklisted_app.push 'zookeeper'
      blacklisted_app.push 'zookeeper'
      # Uncomment all security_enabled settings and set them to true
      options.ini.hadoop ?= {}
      options.ini.hadoop.hdfs_clusters ?= {}
      options.ini.hadoop.hdfs_clusters.default ?= {}
      options.ini.hadoop.hdfs_clusters.default.security_enabled = 'true'
      # Disabled for yarn cluster , mapreduce job are submitted to yarn
      # options.ini.hadoop.mapred_clusters ?= {}
      # options.ini.hadoop.mapred_clusters.default ?= {}
      # options.ini.hadoop.mapred_clusters.default.security_enabled = 'true'
      # options.ini.hadoop.mapred_clusters.default.jobtracker_host = "#{rm_host}"
      # options.ini.hadoop.mapred_clusters.default.jobtracker_port = "#{rm_port}"
      options.ini.hadoop.yarn_clusters ?= {}
      options.ini.hadoop.yarn_clusters.default ?= {}
      options.ini.hadoop.yarn_clusters.default.security_enabled = 'true'
      options.ini.hcatalog ?= {}
      options.ini.hcatalog.security_enabled = 'true'
      options.ini['desktop']['app_blacklist'] ?= blacklisted_app.join()

## Configure notebooks

      options.ini['notebook'] ?= {}
      options.ini['notebook']['show_notebooks'] ?= true
      # Set up some interpreters settings
      options.ini['notebook']['interpreters'] ?= {}
      options.ini['notebook']['interpreters']['hive'] ?= {}
      options.ini['notebook']['interpreters']['hive']['name'] ?= 'Hive'
      options.ini['notebook']['interpreters']['hive']['interface'] ?= 'hiveserver2'
      if  blacklisted_app.indexOf 'spark' is -1
        options.ini['notebook']['interpreters']['sparksql'] ?= {}
        options.ini['notebook']['interpreters']['sparksql']['name'] ?= 'SparkSql'
        options.ini['notebook']['interpreters']['sparksql']['interface'] ?= 'hiveserver2'
        options.ini['notebook']['interpreters']['spark'] ?= {}
        options.ini['notebook']['interpreters']['spark']['name'] ?= 'Scala'
        options.ini['notebook']['interpreters']['spark']['interface'] ?= 'livy'
        options.ini['notebook']['interpreters']['pyspark'] ?= {}
        options.ini['notebook']['interpreters']['pyspark']['name'] ?= 'PySpark'
        options.ini['notebook']['interpreters']['pyspark']['interface'] ?= 'livy'
        options.ini['notebook']['interpreters']['r'] ?= {}
        options.ini['notebook']['interpreters']['r']['name'] ?= 'r'
        options.ini['notebook']['interpreters']['r']['interface'] ?= 'livy-batch'

## Configuration for Proxy Users

      for srv in service.deps.httpfs
        srv.options.httpfs_site ?= {}
        srv.options.httpfs_site["httpfs.proxyuser.#{options.user.name}.hosts"] ?= '*'
        srv.options.httpfs_site["httpfs.proxyuser.#{options.user.name}.groups"] ?= '*'
      for srv in service.deps.oozie_server
        srv.options.oozie_site ?= {}
        srv.options.oozie_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.hosts"] ?= '*'
        srv.options.oozie_site["oozie.service.ProxyUserService.proxyuser.#{options.user.name}.groups"] ?= '*'

## Proxy Users

Hive Hcatalog, Hive Server2 and HBase retrieve their proxy users from the 
hdfs_client configuration directory.

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
      enrich_proxy_user srv for srv in service.deps.hdfs_client
      enrich_proxy_user srv for srv in service.deps.yarn_ts
      enrich_proxy_user srv for srv in service.deps.mapred_jhs
      # enrich_proxy_user srv for srv in service.deps.hive_server2
      # enrich_proxy_user srv for srv in service.deps.hive_webhcat

## Wait

      options.wait_db_admin = service.deps.db_admin.options.wait
      options.wait ?= {}
      options.wait.http ?= for srv in service.deps.huedocker
        host: srv.node.fqdn
        port: srv.options.port or options.port or '8888'

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
    db = require '@nikitajs/core/lib/misc/db'

[home]: http://gethue.com
[hdp-2.3.2.0-hue]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/prerequisites_hue.html)
