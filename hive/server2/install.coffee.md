
# Hive Server2 Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

HDP 2.1 and 2.2 dont support secured Hive metastore in HA mode, see
[HIVE-9622](https://issues.apache.org/jira/browse/HIVE-9622).

Resources:
*   [Cloudera security instruction for CDH5](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_sg_hiveserver2_security.html)

    module.exports =  header: 'Hive Server2 Install', handler: ->
      {hive} = @config.ryba
      {ssl, ssl_server, ssl_client, hadoop_conf_dir, realm} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]
      tmp_location = "/var/tmp/ryba/ssl"
      hive_server_port = if hive.server2.site['hive.server2.transport.mode'] is 'binary'
      then hive.server2.site['hive.server2.thrift.port']
      else hive.server2.site['hive.server2.thrift.http.port']

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Wait

      @call once: true, 'ryba/hive/hcatalog/wait'

## IPTables

| Service        | Port  | Proto | Parameter            |
|----------------|-------|-------|----------------------|
| Hive Server    | 10001 | tcp   | env[HIVE_PORT]       |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: hive_server_port, protocol: 'tcp', state: 'NEW', comment: "Hive Server" }]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: parseInt(hive.server2.env["JMXPORT"],10), protocol: 'tcp', state: 'NEW', comment: "HiveServer2 JMX" } if hive.server2.env["JMXPORT"]?
      @tools.iptables
        header: 'IPTables'
        rules: rules
        if: @config.iptables.action is 'start'

## Identities

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep hive
hive:x:493:493:Hive:/var/lib/hive:/sbin/nologin
cat /etc/group | grep hive
hive:x:493:
```

      @system.group header: 'Group', hive.group
      @system.user header: 'User', hive.user

## Startup

Install the "hive-server2" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

The server is not activated on startup because they endup as zombies if HDFS
isnt yet started.

      @call header: 'Service', ->
        @service
          name: 'hive'
        @service
          name: 'hive-server2'
        @hdp_select
          name: 'hive-server2'
        @service.init
          header: 'Init Script'
          source: "#{__dirname}/../resources/hive-server2.j2"
          local: true
          context: @config.ryba
          target: '/etc/init.d/hive-server2'
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: hive.server2.pid_dir
          uid: hive.user.name
          gid: hive.group.name
          perm: '0750'

## Configuration

      @hconfigure
        header: 'Hive Site'
        target: "#{hive.server2.conf_dir}/hive-site.xml"
        source: "#{__dirname}/../../resources/hive/hive-site.xml"
        local: true
        properties: hive.server2.site
        merge: true
        backup: true
        uid: hive.user.name
        gid: hive.group.name
        mode: 0o0750
      @file.render
        header: 'Hive Log4j properties'
        source: "#{__dirname}/../resources/hive-exec-log4j.properties"
        local: true
        target: "#{hive.server2.conf_dir}/hive-exec-log4j.properties"
        context: @config
      @file.properties
        header: 'Hive server Log4j properties'
        target: "#{hive.server2.conf_dir}/hive-log4j.properties"
        content: hive.server2.log4j.config
        backup: true

## Env

Enrich the "hive-env.sh" file with the value of the configuration property
"ryba.hive.server2.opts". Internally, the environmental variable
"HADOOP_CLIENT_OPTS" is enriched and only apply to the Hive Server2.

Using this functionnality, a user may for example raise the heap size of Hive
Server2 to 4Gb by setting a value equal to "-Xmx4096m".

      @file.render
        header: 'Hive Server2 Env'
        source: "#{__dirname}/../resources/hive-env.sh.j2"
        target: "#{hive.server2.conf_dir}/hive-env.sh"
        local: true
        context: @config
        eof: true
        backup: true
        mode: 0o0750
        uid: hive.user.name
        gid: hive.group.name
        write: [
          match: RegExp "^export HIVE_CONF_DIR=.*$", 'mg'
          replace: "export HIVE_CONF_DIR=#{hive.server2.conf_dir}"
        ]

## Layout

Create the directories to store the logs and pid information. The properties
"ryba.hive.server2.log\_dir" and "ryba.hive.server2.pid\_dir" may be modified.

      @call header: 'Layout', ->
        @system.mkdir
          target: hive.server2.log_dir
          uid: hive.user.name
          gid: hive.group.name
          parent: true
        @system.mkdir
          target: hive.server2.pid_dir
          uid: hive.user.name
          gid: hive.group.name
          parent: true

## SSL

      @call
        header: 'Client SSL'
        if: -> @config.ryba.hive.server2.site['hive.server2.use.SSL'] is 'true'
      , ->
        @java.keystore_add
          keystore: hive.server2.site['hive.server2.keystore.path']
          storepass: hive.server2.site['hive.server2.keystore.password']
          caname: "hive_root_ca"
          cacert: ssl.cacert.source
          key: ssl.key.source
          cert: ssl.cert.source
          keypass: ssl_server['ssl.server.keystore.keypassword']
          name: @config.shortname
          local: ssl.cacert.local
        # @java.keystore_add
        #   keystore: hive.server2.site['hive.server2.keystore.path']
        #   storepass: hive.server2.site['hive.server2.keystore.password']
        #   caname: "hadoop_root_ca"
        #   cacert: ssl.cacert.source
        #   local: ssl.cacert.local
        @service
          srv_name: 'hive-server2'
          action: 'restart'
          if: -> @status()

## Kerberos

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: hive.server2.site['hive.server2.authentication.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hive.server2.site['hive.server2.authentication.kerberos.keytab']
        uid: hive.user.name
        gid: hive.group.name
        unless: @has_service('ryba/hive/hcatalog') and hive.server2.site['hive.metastore.kerberos.principal'] is hive.server2.site['hive.server2.authentication.kerberos.principal']

## Ulimit

      @system.limits
        header: 'Ulimit'
        user: hive.user.name
      , hive.user.limits

## Ranger Hive Plugin Install

      @call
        if: -> @contexts('ryba/ranger/admin').length > 0
      , ->
        @call 'ryba/ranger/plugins/hiveserver2/install'

## Dependencies

    path = require 'path'
