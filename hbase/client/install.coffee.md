
# HBase Client Install

Install the HBase client package and configure it with secured access.

    module.exports =  header: 'HBase Client Install', handler: ({options}) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

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

## Packages

      @service
        name: 'hbase'
      @hdp_select
        name: 'hbase-client'

## Zookeeper JAAS

JAAS configuration files for zookeeper to be deployed on the HBase Master,
RegionServer, and HBase client host machines.

      @file.jaas
        header: 'Zookeeper JAAS'
        target: "#{options.conf_dir}/hbase-client.jaas"
        content: Client:
          useTicketCache: 'true'
        uid: options.user.name
        gid: options.group.name
        mode: 0o644

## Configure

Note, we left the permission mode as default, Master and RegionServer need to

      @hconfigure
        header: 'HBase Site'
        target: "#{options.conf_dir}/hbase-site.xml"
        source: "#{__dirname}/../resources/hbase-site.xml"
        local: true
        properties: options.hbase_site
        mode: 0o0644
        merge: false
        backup: true

# Opts

Environment passed to the Master before it starts.

      @call header: 'HBase Env', ->
        HBASE_OPTS = options.opts.base
        HBASE_OPTS += " -D#{k}=#{v}" for k, v of options.opts.java_properties
        HBASE_OPTS += " #{k}#{v}" for k, v of options.opts.jvm
        @file.render
          header: 'Env'
          target: "#{options.conf_dir}/hbase-env.sh"
          source: "#{__dirname}/../resources/hbase-env.sh.j2"
          local: true
          context:
            HBASE_OPTS: HBASE_OPTS
            JAVA_HOME: options.java_home
          mode: 0o644
          eof: true
          # Fix mapreduce looking for "mapreduce.tar.gz"
          # migration: wdavidw 170905, comment to see if it still apply
          # write: [
          #   match: /^export HBASE_OPTS=\"(.*)\$\{HBASE_OPTS\} -Djava.security.auth.login.config(.*)$/m
          #   replace: "export HBASE_OPTS=\"${HBASE_OPTS} -Dhdp.version=$HDP_VERSION -Djava.security.auth.login.config=#{options.conf_dir}/hbase-client.jaas\" # HDP VERSION FIX RYBA, HBASE CLIENT ONLY"
          #   append: true
          # ]
          # migration: wdavidw 170905, added
          write: for k, v of options.env
            match: RegExp "export #{k}=.*", 'm'
            replace: "export #{k}=\"#{v}\" # RYBA ENV, DONT OVERWRITE"
            append: true
