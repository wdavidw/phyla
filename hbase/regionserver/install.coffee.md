
# HBase RegionServer Install

    module.exports = header: 'HBase RegionServer Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## IPTables

| Service                      | Port  | Proto | Info                         |
|------------------------------|-------|-------|------------------------------|
| HBase Region Server          | 60020 | http  | hbase.regionserver.port      |
| HMaster Region Server Web UI | 60030 | http  | hbase.regionserver.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.regionserver.port'], protocol: 'tcp', state: 'NEW', comment: "HBase RegionServer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.regionserver.info.port'], protocol: 'tcp', state: 'NEW', comment: "HBase RegionServer Info Web UI" }
        ]

## Identities

By default, the "hbase" package create the following entries:

```bash
cat /etc/passwd | grep hbase
hbase:x:492:492:HBase:/var/run/hbase:/bin/bash
cat /etc/group | grep hbase
hbase:x:492:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user


## HBase Regionserver Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @system.mkdir
          target: options.conf_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @system.mkdir
          target: hbase.rs.tmp_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## Service

Install the "hbase-regionserver" service, symlink the rc.d startup script
inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', ->
        @service
          name: 'hbase-regionserver'
        @hdp_select
          name: 'hbase-client'
        @hdp_select
          name: 'hbase-regionserver'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Init Script'
          source: "#{__dirname}/../resources/hbase-regionserver.j2"
          local: true
          context: options: options
          target: '/etc/init.d/hbase-regionserver'
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hbase-regionserver.service'
            source: "#{__dirname}/../resources/hbase-regionserver-systemd.j2"
            local: true
            context: options: options
            mode: 0o0640
          @system.tmpfs
            header: 'Run dir'
            mount: options.pid_dir
            uid: options.user.name
            gid: options.group.name
            perm: '0755'

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

      @file.jaas
        header: 'Zookeeper JAAS'
        target: "#{options.conf_dir}/hbase-regionserver.jaas"
        content: Client:
          principal: options.hbase_site['hbase.regionserver.kerberos.principal'].replace '_HOST', options.fqdn
          keyTab: options.hbase_site['hbase.regionserver.keytab.file']
        uid: options.user.name
        gid: options.group.name

## Kerberos

      @system.copy
        header: 'Copy Keytab'
        if: options.copy_master_keytab
        source: options.copy_master_keytab
        target: options.hbase_site['hbase.regionserver.keytab.file']
      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        unless: options.copy_master_keytab
        principal: options.hbase_site['hbase.regionserver.kerberos.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.hbase_site['hbase.regionserver.keytab.file']
        uid: options.user.name
        gid: options.hadoop_group.name

## Configure

*   [New Security Features in Apache HBase 0.98: An Operator's Guide][secop].

[secop]: http://fr.slideshare.net/HBaseCon/features-session-2

      @hconfigure
        header: 'HBase Site'
        target: "#{options.conf_dir}/hbase-site.xml"
        source: "#{__dirname}/../resources/hbase-site.xml"
        local: true
        properties: options.hbase_site
        merge: false
        uid: options.user.name
        gid: options.group.name
        mode: 0o0600 # See slide 33 from [Operator's Guide][secop]
        backup: true

## Opts

Environment passed to the RegionServer before it starts.

      @call header: 'HBase Env', ->
        options.java_opts += " -D#{k}=#{v}" for k, v of options.opts
        options.java_opts += " -Xms#{options.heapsize} -Xmx#{options.heapsize}"
        @file.render
          target: "#{options.conf_dir}/hbase-env.sh"
          source: "#{__dirname}/../resources/hbase-env.sh.j2"
          backup: true
          uid: options.user.name
          gid: options.group.name
          mode: 0o750
          local: true
          context: options: options
          write: for k, v of options.env
            match: RegExp "export #{k}=.*", 'm'
            replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
            append: true
          unlink: true
          eof: true

## RegionServers

Upload the list of registered RegionServers.

      regionservers = for fqdn, active of options.regionservers
        continue unless active
        fqdn
      @file
        header: 'Registered RegionServers'
        target: "#{options.conf_dir}/regionservers"
        content: (
          for fqdn, active of options.regionservers
            continue unless active
            fqdn
        ).join '\n'
        uid: options.user.name
        gid: options.hadoop_group.name
        eof: true
        mode: 0o640

## Metrics

Enable stats collection in Ganglia and Graphite

      @file.properties
        header: 'Metrics'
        target: "#{options.conf_dir}/hadoop-metrics2-hbase.properties"
        content: options.metrics.config
        backup: true
        mode: 0o0640
        uid: options.user.name
        gid: options.group.name

# User limits

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

## Logging

      @file
        header: 'Log4J'
        target: "#{options.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
        write: for k, v of options.log4j.properties
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true

## Ranger HBase Plugin Install

      # @call
      #   if: -> @contexts('ryba/ranger/admin').length > 0
      # , ->
      #   @call -> @config.ryba.hbase_plugin_is_master = false
      #   @call 'ryba/ranger/plugins/hbase/install'

# Module dependencies

    quote = require 'regexp-quote'
