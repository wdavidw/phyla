
# Shinken Poller Install

    module.exports = header: 'Shinken Poller Install', handler: (options) ->

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-poller   | 7771  |  tcp  |   options.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: options.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller" }]
      for name, mod of options.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller #{name}" }
      @tools.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller" }
        ]
        if: options.iptables
        
## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Package

      @call header: 'Packages', ->
        @service name: 'net-snmp'
        @service name: 'net-snmp-utils'
        @service name: 'httpd'
        @service name: 'fping'
        @service name: 'krb5-devel'
        @service name: 'zlib-devel'
        @service name: 'bzip2-devel'
        @service name: 'openssl-devel'
        @service name: 'ncurses-devel'
        @service name: 'python-devel'
        @service name: 'openldap-devel'
        @service name: 'shinken-poller'

## Configuration

      @file.ini
        header: 'Configuration'
        target: '/etc/shinken/daemons/pollerd.ini'
        content: daemon: options.ini
        backup: true
        eof: true

      @service.init
        header: 'Systemd Script'
        target: '/usr/lib/systemd/system/shinken-poller.service'
        source: "#{__dirname}/resources/shinken-poller-systemd.j2"
        local: true
        mode: 0o0644

## Modules

      @call header: 'Modules', ->
        installmod = (name, mod) =>
          @call unless_exec: "shinken inventory | grep #{name}", ->
            @file.download
              target: "#{options.build_dir}/#{mod.archive}.#{mod.format}"
              source: mod.source
              cache_file: "#{mod.archive}.#{mod.format}"
              unless_exec: "shinken inventory | grep #{name}"
            @tools.extract
              source: "#{options.build_dir}/#{mod.archive}.#{mod.format}"
            @system.execute
              cmd: "shinken install --local #{options.build_dir}/#{mod.archive}"
            @system.remove target: "#{options.build_dir}/#{mod.archive}.#{mod.format}"
            @system.remove target: "#{options.build_dir}/#{mod.archive}"
          for subname, submod of mod.modules then installmod subname, submod
        for name, mod of options.modules then installmod name, mod

## Python Modules

      @call header: 'Python Modules', ->
        install_dep = (k, v) =>
          @call unless_exec: "pip list | grep #{k}", ->
            @file.download
              source: v.url
              target: "#{options.build_dir}/#{v.archive}.#{v.format}"
              cache_file: "#{v.archive}.#{v.format}"
            @tools.extract
              source: "#{options.build_dir}/#{v.archive}.#{v.format}"
            @system.execute
              cmd:"""
              cd #{options.build_dir}/#{v.archive}
              python setup.py build
              python setup.py install
              """
            @system.remove target: "#{options.build_dir}/#{v.archive}.#{v.format}"
            @system.remove target: "#{options.build_dir}/#{v.archive}"
        for _, mod of options.modules then for k,v of mod.python_modules then install_dep k, v

## Plugins

      @call header: 'Plugins', ->
      for plugin in glob.sync "#{__dirname}/resources/plugins/*"
        @file.download
          target: "#{shinken.plugin_dir}/#{path.basename plugin}"
          source: plugin
          uid: options.user.name
          gid: shinken.group.name
          mode: 0o0755

## Executor

      @call header: 'Executor', ->
        @krb5.addprinc options.krb5.admin,
          header: 'Kerberos'
          principal: options.krb5_principal
          randkey: true
          keytab: options.krb5_keytab
          mode: 0o644

        @call
          header: 'SSL'
          if: options.ssl.enabled
        , ->
          @file.download
            source: options.ssl.cert.source
            target: options.tls_cert_file
            local: options.ssl.cert.local
            uid: options.user.name
            gid: options.group.name
          @file.download
            source: options.ssl.key.source
            target: options.tls_key_file
            local: options.ssl.key.local
            uid: options.user.name
            gid: options.group.name

        @call header: 'Docker', ->
          options.image ?= '@rybajs/metal/shinken-poller-executor'
          options.version ?= 'latest'
          @call (_, callback) ->
            @docker.checksum
              docker: options.swarm_conf
              image: options.image
              tag: options.version
            , (err, status, checksum) ->
              return callback err, checksum
          @docker.pull
            header: 'Pull container'
            unless: -> @status(-1)
            tag: options.image
            version: options.version
            code_skipped: 1
          @file.download
            unless: -> @status(-1) or @status(-2)
            source: "#{options.cache_dir or '.'}/shinken-poller-executor.tar"
            target: '/var/lib/docker_images/shinken-poller-executor.tar'
            binary: true
            # md5: md5
          @docker.load
            header: 'Load container to docker'
            unless: -> @status(-3)
            if_exists: '/var/lib/docker_images/shinken-poller-executor.tar'
            source: '/var/lib/docker_images/shinken-poller-executor.tar'
            docker: options.swarm_conf
          @file
            target: "#{options.user.home}/resources/cronfile"
            content: """
            01 */9 * * * #{options.user.name} /usr/bin/kinit #{options.krb5_principal} -kt #{options.krb5_keytab}
            """
            eof: true
          volumes = [
            "/etc/krb5.conf:/etc/krb5.conf:ro"
            "/etc/localtime:/etc/localtime:ro"
            "#{options.user.home}/resources/cronfile:/etc/cron.d/1cron"
            "#{options.krb5_keytab}:#{options.krb5_keytab}"
          ]
          if options.ssl?
            volumes.push "#{options.tls_cert_file}:#{options.credentials.swarm_user.cert}" if options.credentials.swarm_user.cert?
            volumes.push "#{options.tls_key_file}:#{options.credentials.swarm_user.key}" if options.credentials.swarm_user.key?
          @docker.service
            name: 'poller-executor'
            image: "#{options.image}:#{options.version}"
            net: 'host'
            volume: volumes

## Dependencies

    path = require 'path'
    glob = require 'glob'
