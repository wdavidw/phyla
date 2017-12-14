
# HBase Rest Gateway Install

Note, Hortonworks recommand to grant administrative access to the _acl_ table
for the service princial define by "hbase.rest.kerberos.principal". For example,
run the command `grant '$USER', 'RWCA'`. Ryba isnt doing it because we didn't
have usecase for it yet.

    module.exports =  header: 'HBase Rest Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service                    | Port  | Proto | Info                   |
|----------------------------|-------|-------|------------------------|
| HBase REST Server          | 60080 | http  | hbase.rest.port        |
| HBase REST Server Web UI   | 60085 | http  | hbase.rest.info.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'Iptables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.rest.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.rest.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
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

## HBase Rest Server Layout

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

## HBase Rest Service

      @call header: 'Service', ->
        @service
          name: 'hbase-rest'
        @hdp_select
          name: 'hbase-client'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Init Script'
          source: "#{__dirname}/../resources/hbase-rest.j2"
          local: true
          context: options: options
          target: '/etc/init.d/hbase-rest'
          mode: 0o0755
          unlink: true
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hbase-rest.service'
            source: "#{__dirname}/../resources/hbase-rest-systemd.j2"
            local: true
            context: options: options
            mode: 0o0640
          @system.tmpfs
            header: 'Run dir'
            mount: options.pid_dir
            uid: options.user.name
            gid: options.group.name
            perm: '0755'

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the rest server.

      @hconfigure
        header: 'HBase Site'
        target: "#{options.conf_dir}/hbase-site.xml"
        source: "#{__dirname}/../resources/hbase-site.xml"
        local: true
        properties: options.hbase_site
        uid: options.user.name
        gid: options.group.name
        mode: 0o600
        backup: true

## Env

Environment passed to the HBase Rest Server before it starts.

      @call header: 'HBase Env', ->
        HBASE_REST_OPTS = options.opts.base
        HBASE_REST_OPTS += " -D#{k}=#{v}" for k, v of options.opts.java_properties
        HBASE_REST_OPTS += " #{k}#{v}" for k, v of options.opts.jvm
        @file.render
          header: 'Hbase Env'
          target: "#{options.conf_dir}/hbase-env.sh"
          source: "#{__dirname}/../resources/hbase-env.sh.j2"
          local: true
          context:
            HBASE_REST_OPTS: HBASE_REST_OPTS
            JAVA_HOME: options.java_home
          mode: 0o0750
          uid: options.user.name
          gid: options.group.name
          unlink: true
          write: for k, v of options.env
            match: RegExp "export #{k}=.*", 'm'
            replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"

## Kerberos

Create the Kerberos keytab for the service principal.

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.hbase_site['hbase.rest.kerberos.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.hbase_site['hbase.rest.keytab.file']
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
