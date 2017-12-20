
# Shinken Reactionner Install

    module.exports = header: 'Shinken Reactionner Install', handler: (options) ->

## SSH

      @call
        header: 'SSH'
        if: -> options.ssh?.private_key? and options.ssh?.public_key?
      , ->
        @system.mkdir
          target: "#{options.user.home}/.ssh"
          mode: 0o700
          uid: options.user.name
          gid: options.user.gid
        @file
          target: "#{options.user.home}/.ssh/id_rsa"
          content: options.ssh.private_key
          eof: true
          mode: 0o600
          uid: options.user.name
          gid: options.user.gid
        @file
          target: "#{options.user.home}/.ssh/id_rsa.pub"
          content: options.ssh.public_key
          eof: true
          mode: 0o644
          uid: options.user.name
          gid: options.user.gid

## IPTables

| Service             | Port  | Proto | Parameter        |
|---------------------|-------|-------|------------------|
| shinken-reactionner | 7769  |  tcp  |    config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: options.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Reactionner" }]
      for name, mod of options.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Reactionner #{name}" }
      @tools.iptables
        header: 'IPTables'
        rules: rules
        if: options.iptables

## Packages

      @service
        header: 'Packages'
        name: 'shinken-reactionner'

## Configuration

      @file.ini
        header: 'Configuration'
        target: '/etc/shinken/daemons/reactionnerd.ini'
        content: daemon: options.ini
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
        for name, mod of options.modules then installmod name, mod

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
        for _, mod of options.modules then for k,v of mod.python_modules then install_dep k, v
