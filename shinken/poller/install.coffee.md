
# Shinken Poller Install

    module.exports = header: 'Shinken Poller Install', handler: ->
      {shinken, monitoring} = @config.ryba
      {poller} = @config.ryba.shinken
      {realm} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-poller   | 7771  |  tcp  |   poller.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: poller.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller" }]
      for name, mod of poller.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller #{name}" }
      @tools.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: poller.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Poller" }
        ]
        if: @config.iptables.action is 'start'

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
        @service name: 'shinken-poller'

## Configuration

      @file.ini
        header: 'Configuration'
        target: '/etc/shinken/daemons/pollerd.ini'
        content: daemon: poller.ini
        backup: true
        eof: true

## Modules

      @call header: 'Modules', ->
        installmod = (name, mod) =>
          @call unless_exec: "shinken inventory | grep #{name}", ->
            @file.download
              target: "#{shinken.build_dir}/#{mod.archive}.#{mod.format}"
              source: mod.source
              cache_file: "#{mod.archive}.#{mod.format}"
              unless_exec: "shinken inventory | grep #{name}"
            @tools.extract
              source: "#{shinken.build_dir}/#{mod.archive}.#{mod.format}"
            @system.execute
              cmd: "shinken install --local #{shinken.build_dir}/#{mod.archive}"
            @system.remove target: "#{shinken.build_dir}/#{mod.archive}.#{mod.format}"
            @system.remove target: "#{shinken.build_dir}/#{mod.archive}"
          for subname, submod of mod.modules then installmod subname, submod
        for name, mod of poller.modules then installmod name, mod

## Python Modules

      @call header: 'Python Modules', ->
        install_dep = (k, v) =>
          @call unless_exec: "pip list | grep #{k}", ->
            @file.download
              source: v.url
              target: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
              cache_file: "#{v.archive}.#{v.format}"
            @tools.extract
              source: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
            @system.execute
              cmd:"""
              cd #{shinken.build_dir}/#{v.archive}
              python setup.py build
              python setup.py install
              """
            @system.remove target: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
            @system.remove target: "#{shinken.build_dir}/#{v.archive}"
        for _, mod of poller.modules then for k,v of mod.python_modules then install_dep k, v

## Plugins

      @call header: 'Plugins', ->
      for plugin in glob.sync "#{__dirname}/resources/plugins/*"
        @file.download
          target: "#{shinken.plugin_dir}/#{path.basename plugin}"
          source: plugin
          uid: shinken.user.name
          gid: shinken.group.name
          mode: 0o0755

## Executor

      @call header: 'Executor', ->
        @krb5.addprinc krb5,
          header: 'Kerberos'
          principal: shinken.poller.executor.krb5.principal
          randkey: true
          keytab: shinken.poller.executor.krb5.keytab
          mode: 0o644

        @call
          header: 'SSL'
          if: shinken.poller.executor.ssl?
        , ->
          @file shinken.poller.executor.ssl.cert
          @file shinken.poller.executor.ssl.key

        @call header: 'Docker', ->
          @file.download
            source: "#{@config.nikita.cache_dir or '.'}/shinken-poller-executor.tar"
            target: '/var/lib/docker_images/shinken-poller-executor.tar'
          @docker.load
            source: '/var/lib/docker_images/shinken-poller-executor.tar'
            if: -> @status -1
          @file
            target: "#{shinken.user.home}/resources/cronfile"
            content: """
            01 */9 * * * #{shinken.user.name} /usr/bin/kinit #{shinken.poller.executor.krb5.principal} -kt #{shinken.poller.executor.krb5.keytab}
            """
            eof: true
          volumes = [
            "/etc/krb5.conf:/etc/krb5.conf:ro"
            "/etc/localtime:/etc/localtime:ro"
            "#{shinken.user.home}/resources/cronfile:/etc/cron.d/1cron"
            "#{shinken.poller.executor.krb5.keytab}:#{shinken.poller.executor.krb5.keytab}"
          ]
          if shinken.poller.executor.ssl?
            volumes.push "#{shinken.poller.executor.ssl.cert.target}:#{monitoring.credentials.swarm_user.cert}"
            volumes.push "#{shinken.poller.executor.ssl.key.target}:#{monitoring.credentials.swarm_user.key}"
          @docker.service
            name: 'poller-executor'
            image: 'ryba/shinken-poller-executor'
            net: 'host'
            volume: volumes
## Dependencies

    path = require 'path'
    glob = require 'glob'
