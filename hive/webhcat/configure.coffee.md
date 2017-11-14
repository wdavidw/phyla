
# Configure webhcat server

    module.exports = (service) ->
      options = service.options

## Environment

      # Layout
      options.conf_dir ?= '/etc/hive-webhcat/conf'
      options.log_dir ?= '/var/log/webhcat'
      options.pid_dir ?= '/var/run/webhcat'
      # Opts and Java
      options.java_opts ?= ''
      options.opts ?= {}
      # Misc
      options.fqdn ?= service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # throw Error 'Required Options: "realm"' unless options.krb5.realm
      # options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      # Kerberos HDFS Admin
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Identities

      # Hadoop Group
      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.deps.hive_hcatalog[0].options.group, options.group
      options.user = merge {}, service.deps.hive_hcatalog[0].options.user, options.user

## Configuration

      options.webhcat_site ?= {}
      options.webhcat_site['templeton.storage.class'] ?= 'org.apache.hive.hcatalog.templeton.tool.ZooKeeperStorage' # Fix default value distributed in companion files
      options.webhcat_site['templeton.jar'] ?= '/usr/lib/hive-hcatalog/share/options/svr/lib/hive-webhcat-0.13.0.2.1.2.0-402.jar' # Fix default value distributed in companion files
      options.webhcat_site['templeton.hive.properties'] ?= [
        'hive.metastore.local=false'
        "hive.metastore.uris=#{service.deps.hive_hcatalog[0].options.hive_site['hive.metastore.uris'] }"
        'hive.metastore.sasl.enabled=yes'
        'hive.metastore.execute.setugi=true'
        'hive.metastore.warehouse.dir=/apps/hive/warehouse'
        "hive.metastore.kerberos.principal=#{service.deps.hive_hcatalog[0].options.hive_site['hive.metastore.kerberos.principal']}"
      ].join ','
      options.webhcat_site['templeton.zookeeper.hosts'] ?= service.deps.hive_hcatalog[0].options.hive_site['templeton.zookeeper.hosts']
      options.webhcat_site['templeton.kerberos.principal'] ?= "HTTP/#{service.node.fqdn}@#{options.krb5.realm}"
      options.webhcat_site['templeton.kerberos.keytab'] ?= service.deps.hadoop_core.options.core_site['hadoop.http.authentication.kerberos.keytab']
      # The secret used to sign the HTTP cookie value. The default value is a random value. Unless multiple WebHCat instances need to share the secret the random value is adequate.
      options.webhcat_site['templeton.kerberos.secret'] ?= 'secret'
      options.webhcat_site['webhcat.proxyuser.hue.groups'] ?= '*'
      options.webhcat_site['webhcat.proxyuser.hue.hosts'] ?= '*'
      options.webhcat_site['webhcat.proxyuser.knox.groups'] ?= '*'
      options.webhcat_site['webhcat.proxyuser.knox.hosts'] ?= '*'
      options.webhcat_site['templeton.port'] ?= 50111
      options.webhcat_site['templeton.controller.map.mem'] = 1600 # Total virtual memory available to map tasks.

## Logj4 Properties

      options.log4j = merge {}, service.deps.log4j?.options, options.log4j


      options.log4j.properties ?= {}
      options.opts['webhcat.root.logger'] ?= 'INFO,RFA'
      if options.log4j.remote_host and options.log4j.remote_port
        # adding SOCKET appender
        options.log4j.socket_client ?= "SOCKET"
        # Root logger
        if options.opts['webhcat.root.logger'].indexOf(options.log4j.socket_client) is -1
        then options.opts['webhcat.root.logger'] += ",#{options.log4j.socket_client}"

        options.opts['webhcat.log.application'] ?= 'hive-webhcat'
        options.opts['webhcat.log.remote_host'] ?= options.log4j.remote_host
        options.opts['webhcat.log.remote_port'] ?= options.log4j.remote_port

        options.log4j.socket_opts ?=
          Application: '${options.log.application}'
          RemoteHost: '${options.log.remote_host}'
          Port: '${options.log.remote_port}'
          ReconnectionDelay: '10000'

        appender
          type: 'org.apache.log4j.net.SocketAppender'
          name: options.log4j.socket_client
          logj4: options.log4j.properties
          properties: options.log4j.socket_opts

## Wait

      options.wait_krb5_client ?= service.deps.krb5_client.options.wait
      options.wait_zookeeper_server ?= service.deps.zookeeper_server[0].options.wait
      options.wait_hive_hcatalog ?= service.deps.hive_hcatalog[0].options.wait
      options.wait = {}
      options.wait.http = for srv in service.deps.hive_webhcat
        srv.options.webhcat_site ?= {}
        host: srv.node.fqdn
        port: srv.options.webhcat_site['templeton.port'] or 50111

## Dependencies

    appender = require '../../lib/appender'
    {merge} = require 'nikita/lib/misc'
