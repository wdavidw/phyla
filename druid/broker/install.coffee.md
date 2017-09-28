
# Druid Broker Install

    module.exports = header: 'Druid Broker Install', handler: (options) ->

## IPTables

| Service      | Port | Proto    | Parameter                   |
|--------------|------|----------|-----------------------------|
| Druid Broker | 8082 | tcp/http |                             |

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.runtime['druid.port'], protocol: 'tcp', state: 'NEW', comment: "Druid Broker" }
        ]
        if: options.iptables

## Configuration

      @service.init
        header: 'rc.d'
        target: "/etc/init.d/druid-broker"
        source: "#{__dirname}/../resources/druid-broker.j2"
        context: options: options
        local: true
        backup: true
        mode: 0o0755
      @file.properties
        target: "/opt/druid-#{options.version}/conf/druid/broker/runtime.properties"
        content: options.runtime
        backup: true
      @file
        target: "#{options.dir}/conf/druid/broker/jvm.config"
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
