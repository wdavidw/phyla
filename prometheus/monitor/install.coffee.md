
# Prometheus Install

    module.exports = header: 'Prometheus Monitor Install', handler: (options) ->
      tmp_archive_location = "/var/tmp/ryba/prometheus.tar.gz"

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## IPTables

| Service       | Port  | Proto | Parameter   |
|---------------|-------|-------|-------------|
| Prometheus UI | 3000  | http  |  9091       |

      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.port , protocol: 'tcp', state: 'NEW', comment: "Prometheus UI" }
        ]

## Layout

      @system.mkdir
        target: options.conf_dir
        uid: options.user.name
        gid: options.group.name
      @system.mkdir
        target: options.log_dir
        uid: options.user.name
        gid: options.group.name
      @system.mkdir
        target: options.run_dir
        uid: options.user.name
        gid: options.group.name
      @system.mkdir
        target: options.storage.path
        uid: options.user.name
        gid: options.group.name

## Packages
      
      @call
        if_os: name: ['redhat','centos'], version: '7'
      , ->
        @service.init
          header: 'Systemd Script'
          target: '/usr/lib/systemd/system/prometheus-monitor.service'
          source: "#{__dirname}/../resources/prometheus-monitor-systemd.j2"
          local: true
          context: options
          mode: 0o0640
        @system.tmpfs
          header: 'Run dir'
          mount: options.run_dir
          uid: options.user.name
          gid: options.group.name
          perm: '0755'
      @file.download
        source: options.source
        target: tmp_archive_location
      @system.mkdir
        target: options.install_dir
      @tools.extract
        source: tmp_archive_location
        target: options.install_dir
        preserve_owner: false
        strip: 1
      @system.link
        source: options.install_dir
        target: options.latest_dir

# ## SSL
# 
#       @file.download
#         header: 'SSL Cacert'
#         source: options.ssl.cacert.source
#         target: options.config['tls_config']['ca_file']
#         local: options.ssl.cacert.local
#       @file.download
#         header: 'SSL Cert'
#         source: options.ssl.cert.source
#         target: options.config['tls_config']['cert_file']
#         local: options.ssl.cert.local
#       @file.download
#         header: 'SSL Key'
#         source: options.ssl.key.source
#         target: options.config['tls_config']['key_file']
#         local: options.ssl.key.local

## Configuration

      @file.yaml
        target: "#{options.conf_dir}/prometheus.yaml"
        content: options.config
        uid: options.user.name
        gid: options.group.name
        backup: true
        merge: false
