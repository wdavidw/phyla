
# Collectd Exporter Install

    module.exports = header: 'Collectd Exporter Install', handler: (options) ->
      options.tmp_dir ?= '/tmp'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## IPtables

      @tools.iptables
        header: "IPtable"
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.port, protocol: 'tcp', state: 'NEW', comment: "Collectd Exporter" }
        ]

## Packages
      
      @call
        if_os: name: ['redhat','centos'], version: '7'
      , ->
        @service.init
          header: 'Systemd Script'
          target: '/usr/lib/systemd/system/prometheus-collectd-exporter.service'
          source: "#{__dirname}/../resources/prometheus-collectd-exporter-systemd.j2"
          local: true
          context: options
          mode: 0o0640

      @system.mkdir
        target: options.install_dir
      @file.download
        source: options.source
        target: "#{options.tmp_dir}/collectd_exporter.tar.gz"
      @tools.extract
        source: "#{options.tmp_dir}/collectd_exporter.tar.gz"
        target: "#{options.install_dir}"
        strip: 1
