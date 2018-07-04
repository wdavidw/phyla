
# Hive Server2 Install

TODO: Implement lock for Hive Server2
http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.2.0/CDH4-Installation-Guide/cdh4ig_topic_18_5.html

HDP 2.1 and 2.2 dont support secured Hive metastore in HA mode, see
[HIVE-9622](https://issues.apache.org/jira/browse/HIVE-9622).

Resources:
*   [Cloudera security instruction for CDH5](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cdh_sg_hiveserver2_security.html)

    module.exports =  header: 'Hive Server2 Install', handler: (options) ->

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

      hive_server_port = if options.hive_site['hive.server2.transport.mode'] is 'binary'
      then options.hive_site['hive.server2.thrift.port']
      else options.hive_site['hive.server2.thrift.http.port']
      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: hive_server_port, protocol: 'tcp', state: 'NEW', comment: "Hive Server" }]
      rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: parseInt(options.env["JMXPORT"],10), protocol: 'tcp', state: 'NEW', comment: "HiveServer2 JMX" } if options.env["JMXPORT"]?
      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: rules

## Identities

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep hive
hive:x:493:493:Hive:/var/lib/hive:/sbin/nologin
cat /etc/group | grep hive
hive:x:493:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Ulimit

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

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
          context: options: options
          target: '/etc/init.d/hive-server2'
          mode: 0o0755
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          perm: '0750'

## Configuration

      @hconfigure
        header: 'Hive Site'
        target: "#{options.conf_dir}/hive-site.xml"
        source: "#{__dirname}/../../resources/hive/hive-site.xml"
        local: true
        properties: options.hive_site
        merge: true
        backup: true
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750
      @file.render
        header: 'Hive Log4j properties'
        source: "#{__dirname}/../resources/hive-exec-log4j.properties.j2"
        local: true
        target: "#{options.conf_dir}/hive-exec-log4j.properties"
        context: options
      @file.properties
        header: 'Hive server Log4j properties'
        target: "#{options.conf_dir}/hive-log4j.properties"
        content: options.log4j.properties
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
        target: "#{options.conf_dir}/hive-env.sh"
        local: true
        context: options: options
        eof: true
        backup: true
        mode: 0o0750
        uid: options.user.name
        gid: options.group.name
        write: [
          match: RegExp "^export HIVE_CONF_DIR=.*$", 'mg'
          replace: "export HIVE_CONF_DIR=#{options.conf_dir}"
        ]

## Layout

Create the directories to store the logs and pid information. The properties
"ryba.hive.server2.log\_dir" and "ryba.hive.server2.pid\_dir" may be modified.

      @call header: 'Layout', ->
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
          parent: true
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          parent: true

## SSL

      @call
        header: 'SSL'
        if: -> options.hive_site['hive.server2.use.SSL'] is 'true'
      , ->
        @java.keystore_add
          keystore: options.hive_site['hive.server2.keystore.path']
          storepass: options.hive_site['hive.server2.keystore.password']
          key: options.ssl.key.source
          cert: options.ssl.cert.source
          keypass: options.hive_site['hive.server2.keystore.password']
          name: options.ssl.key.name
          local: options.ssl.key.local
        @java.keystore_add
          keystore: options.hive_site['hive.server2.keystore.path']
          storepass: options.hive_site['hive.server2.keystore.password']
          caname: "hadoop_root_ca"
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local
        @service
          srv_name: 'hive-server2'
          action: 'restart'
          if: -> @status()

## Kerberos

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        unless: options.principal_identical_to_hcatalog
        principal: options.hive_site['hive.server2.authentication.kerberos.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.hive_site['hive.server2.authentication.kerberos.keytab']
        uid: options.user.name
        gid: options.group.name

## Ranger Hive Plugin Install
      # 
      # @call
      #   if: -> @contexts('ryba/ranger/admin').length > 0
      # , ->
      #   @call 'ryba/ranger/plugins/hiveserver2/install'

## Dependencies

    path = require 'path'
