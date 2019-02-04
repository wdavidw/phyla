
# Druid Coordinator Install

    module.exports = header: 'Druid Coordinator Install', handler: (options) ->

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Coordinator | 8081 | tcp/http |                             |

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid Coordinator" }
        ]
        if: options.iptables

## Configuration

      @service.init
        header: 'rc.d'
        target: "/etc/init.d/druid-coordinator"
        source: "#{__dirname}/../resources/druid-coordinator.j2"
        context: options: options
        local: true
        backup: true
        mode: 0o0755
      @file.properties
        target: "/opt/druid-#{options.version}/conf/druid/coordinator/runtime.properties"
        content: options.runtime
        backup: true
      @file
        target: "#{options.dir}/conf/druid/coordinator/jvm.config"
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
