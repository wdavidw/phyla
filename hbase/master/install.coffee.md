
# HBase Master Install

TODO: [HBase backup node](http://willddy.github.io/2013/07/02/HBase-Add-Backup-Master-Node.html)

    module.exports =  header: 'HBase Master Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## IPTables

| Service             | Port  | Proto | Info                   |
|---------------------|-------|-------|------------------------|
| HBase Master        | 60000 | http  | hbase.master.port      |
| HMaster Info Web UI | 60010 | http  | hbase.master.info.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        if: options.iptabless
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.master.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.master.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
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


## HBase Master Layout

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
          target: hbase.master.tmp_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## Service

Install the "hbase-master" service, symlink the rc.d startup script inside
"/etc/init.d" and activate it on startup.

      @call header: 'Service', ->
        @service
          name: 'hbase-master'
        @hdp_select
          name: 'hbase-client'
        @hdp_select
          name: 'hbase-master'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Init Script'
          source: "#{__dirname}/../resources/hbase-master.j2"
          local: true
          context: options: options
          target: '/etc/init.d/hbase-master'
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hbase-master.service'
            source: "#{__dirname}/../resources/hbase-master-systemd.j2"
            local: true
            context: options: options
            mode: 0o0640
          @system.tmpfs
            header: 'Run dir'
            mount: options.pid_dir
            uid: options.user.name
            gid: options.group.name
            perm: '0755'

## Compression Libs

Install compression libs as defined in HDP docs

      @call header: 'Compression libs', ->
        @service
          name: 'hadooplzo'
        @service
          name: 'hadooplzo-native'

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

Environment passed to the Master before it starts.

      @call header: 'HBase Env', ->
        options.java_opts += " -D#{k}=#{v}" for k, v of options.opts
        options.java_opts += " -Xms#{options.heapsize} -Xmx#{options.heapsize} "
        @file.render
          target: "#{options.conf_dir}/hbase-env.sh"
          source: "#{__dirname}/../resources/hbase-env.sh.j2"
          backup: true
          local: true
          eof: true
          context: options: options
          mode: 0o750
          uid: options.user.name
          gid: options.group.name
          write: for k, v of options.env
            match: RegExp "export #{k}=.*", 'm'
            replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"
            append: true

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

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

Environment file is enriched by "ryba/hbase" # HBase # Env".

      @file.jaas
        header: 'Zookeeper JAAS'
        target: "#{options.conf_dir}/hbase-master.jaas"
        content: Client:
          principal: options.hbase_site['hbase.master.kerberos.principal'].replace '_HOST', options.fqdn
          keyTab: options.hbase_site['hbase.master.keytab.file']
        uid: options.user.name
        gid: options.group.name
        mode: 0o600

## Kerberos

https://blogs.apache.org/hbase/entry/hbase_cell_security
https://hbase.apache.org/book/security.html

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos Master User'
        principal: options.hbase_site['hbase.master.kerberos.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.hbase_site['hbase.master.keytab.file']
        uid: options.user.name
        gid: options.hadoop_group.name

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos Admin User'
        principal: options.admin.principal
        password: options.admin.password

      @file
        header: 'Log4J Properties'
        target: "#{options.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
        write: for k, v of options.log4j.properties
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true

## Metrics

Enable stats collection in Ganglia and Graphite

      @file.properties
        header: 'Metrics Properties'
        target: "#{options.conf_dir}/hadoop-metrics2-hbase.properties"
        content: options.metrics.properties
        backup: true
        mode: 0o640
        uid: options.user.name
        gid: options.group.name

## SPNEGO

Ensure we have read access to the spnego keytab soring the server HTTP
principal.


      @system.execute
        header: 'SPNEGO'
        cmd: "su -l #{options.user.name} -c 'test -r /etc/security/keytabs/spnego.service.keytab'"

# User limits

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

# Dependencies

    path = require 'path'
    quote = require 'regexp-quote'
