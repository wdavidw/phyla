
# HDFS HttpFS Install

    module.exports = header: 'HDFS HttpFS Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## Identities

By default, the package create the following entries:

```bash
cat /etc/passwd | grep httpfs
httpfs:x:495:494:Hadoop HTTPFS:/var/run/hadoop/httpfs:/bin/bash
cat /etc/group | grep httpfs
httpfs:x:494:httpfs
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## IPTables

| Service   | Port   | Proto  | Parameter       |
|-----------|--------|--------|-----------------|
| datanode  | 14000  | http   | http_port       |
| datanode  | 14001  | http   | http_admin_port |

The "dfs.datanode.address" default to "50010" in non-secured mode. In non-secured
mode, it must be set to a value below "1024" and default to "1004".

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        if: @config.iptables.action is 'start'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.http_port, protocol: 'tcp', state: 'NEW', comment: "HDFS HttpFS" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.http_admin_port, protocol: 'tcp', state: 'NEW', comment: "HDFS HttpFS" }
        ]

## Package

      @call header: 'Package', ->
        @service
          name: 'hadoop-httpfs'
        @hdp_select
          name: 'hadoop-httpfs'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd Script'
          target: "/etc/init.d/hadoop-httpfs"
          source: "#{__dirname}/../resources/hadoop-httpfs.j2"
          local: true
          context: options: options
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-httpfs.service'
            source: "#{__dirname}/../resources/hadoop-httpfs-systemd.j2"
            local: true
            context: options: options
            mode: 0o0644
          @system.tmpfs
            header: 'Run dir'
            mount: "#{options.pid_dir}"
            uid: options.user.name
            gid: options.group.name
            perm: '0755'

## Kerberos

      @call header: 'Kerberos', ->
        @system.copy # SPNEGO Keytab
          source: options.core_site['hadoop.http.authentication.kerberos.keytab']
          target: options.httpfs_site['httpfs.authentication.kerberos.keytab']
          if: options.core_site['hadoop.http.authentication.kerberos.keytab'] isnt options.httpfs_site['httpfs.authentication.kerberos.keytab']
          if_exists: options.core_site['hadoop.http.authentication.kerberos.keytab']
          uid: options.user.name
          gid: options.group.name
          mode: 0o0600
        @krb5.addprinc options.krb5.admin, # Service Keytab
          principal: options.httpfs_site['httpfs.hadoop.authentication.kerberos.principal']
          randkey: true
          keytab: options.httpfs_site['httpfs.hadoop.authentication.kerberos.keytab']
          uid: options.user.name
          gid: options.group.name
          mode: 0o0600

## Environment

      @call header: 'Environment', ->
        @system.mkdir
          target: "#{options.pid_dir}"
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @system.mkdir
          target: "#{options.log_dir}" #/#{hdfs.user.name}
          uid: options.user.name
          gid: options.group.name
          parent: true
        @system.mkdir
          target: "#{options.tmp_dir}"
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @call header: 'HttpFS Env', ->
          options.catalina_opts += " -D#{k}=#{v}" for k, v of options.catalina.opts
          @file.render
            target: "#{options.conf_dir}/httpfs-env.sh"
            source: "#{__dirname}/../resources/httpfs-env.sh.j2"
            local: true
            context: @config
            uid: options.user.name
            gid: options.group.name
            backup: true
            mode: 0o755
        @file.render
          target: "#{options.conf_dir}/httpfs-log4j.properties"
          source: "#{__dirname}/../resources/httpfs-log4j.properties"
          local: true
          context: options
          backup: true
        @system.link
          source: '/usr/hdp/current/hadoop-httpfs/webapps'
          target: "#{options.catalina_home}/webapps"
        @system.mkdir # CATALINA_TMPDIR
          target: "#{options.catalina_home}/temp"
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
        @system.mkdir
          target: "#{options.catalina_home}/work"
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
        @system.copy # Copie original server.xml for no-SSL environments
          source: "#{options.catalina_home}/conf/server.xml"
          target: "#{options.catalina_home}/conf/nossl-server.xml"
          unless_exists: true
        @system.copy
          source: "#{options.catalina_home}/conf/nossl-server.xml"
          target: "#{options.catalina_home}/conf/server.xml"
          unless: options.env.HTTPFS_SSL_ENABLED is 'true'
        @system.copy
          source: "#{options.catalina_home}/conf/ssl-server.xml"
          target: "#{options.catalina_home}/conf/server.xml"
          if: options.env.HTTPFS_SSL_ENABLED is 'true'

## Configuration

      @hconfigure
        header: 'Configuration'
        target: "#{options.conf_dir}/httpfs-site.xml"
        properties: options.httpfs_site
        uid: options.user.name
        gid: options.group.name
        backup: true

## SSL

      @call header: 'SSL', if: options.env.HTTPFS_SSL_ENABLED is 'true', ->
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          keystore: options.env.HTTPFS_SSL_KEYSTORE_FILE
          storepass: options.env.HTTPFS_SSL_KEYSTORE_PASS
          key: options.ssl.key.source
          cert: options.ssl.cert.source
          keypass: options.env.HTTPFS_SSL_KEYSTORE_PASS
          name: options.ssl.key.name
          local: options.ssl.key.local
          uid: options.user.name
          gid: options.group.name
          mode: 0o0640
        @java.keystore_add
          keystore: options.env.HTTPFS_SSL_KEYSTORE_FILE
          storepass: options.env.HTTPFS_SSL_KEYSTORE_PASS
          caname: "hadoop_root_ca"
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local

## Dependencies

    path = require 'path'
