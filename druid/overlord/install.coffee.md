
# Druid Overlord Install

    module.exports = header: 'Druid Overlord Install', handler: (options) ->

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Overlord    | 8090 | tcp/http |                             |

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid Broker" }
        ]
        if: options.iptables

## Configuration

      @service.init
        header: 'rc.d'
        target: "/etc/init.d/druid-overlord"
        source: "#{__dirname}/../resources/druid-overlord.j2"
        context: options: options
        local: true
        backup: true
        mode: 0o0755
      @file.properties
        target: "/opt/druid-#{options.version}/conf/druid/overlord/runtime.properties"
        content: options.runtime
        backup: true
      @file
        target: "#{options.dir}/conf/druid/overlord/jvm.config"
        write: [
          match: /^-Xms.*$/m
          replace: "-Xms#{options.jvm.xms}"
        ,
          match: /^-Xmx.*$/m
          replace: "-Xmx#{options.jvm.xmx}"
        ,
          match: /^-Duser.timezone=.*$/m
          replace: "-Duser.timezone=#{options.timezone}"
        ]
