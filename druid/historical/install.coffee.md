
# Druid Historical Install

    module.exports = header: 'Druid Historical Install', handler: (options) ->

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Historical  | 8083 | tcp/http |                             |

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid Historical" }
        ]
        if: options.iptables

## Configuration

      @service.init
        header: 'rc.d'
        target: "/etc/init.d/druid-historical"
        source: "#{__dirname}/../resources/druid-historical.j2"
        context: options: options
        local: true
        backup: true
        mode: 0o0755
      @file.properties
        header: 'Runtime'
        target: "/opt/druid-#{options.version}/conf/druid/historical/runtime.properties"
        content: options.runtime
        backup: true
      @file
        header: 'JVM'
        target: "#{options.dir}/conf/druid/historical/jvm.config"
        write: [
          match: /^-Xms.*$/m
          replace: "-Xms#{options.jvm.xms}"
        ,
          match: /^-Xmx.*$/m
          replace: "-Xmx#{options.jvm.xmx}"
        ,
          match: /^-XX:MaxDirectMemorySize=.*$/m
          replace: "-XX:MaxDirectMemorySize=#{options.jvm.max_direct_memory_size}"
        ,
          match: /^-Duser.timezone=.*$/m
          replace: "-Duser.timezone=#{options.timezone}"
        ]
      @system.mkdir (
        target: "#{path.resolve options.dir, location.path}"
        uid: "#{options.user.name}"
        gid: "#{options.group.name}"
      ) for location in JSON.parse options.runtime['druid.segmentCache.locations']

## Dependencies

    path = require 'path'
