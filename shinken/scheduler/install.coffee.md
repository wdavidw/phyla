
# Shinken Scheduler Install

    module.exports = header: 'Shinken Scheduler Install', handler: (options) ->


## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
| shinken-scheduler | 7768  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Scheduler" }
        ]
        if: options.iptables

## Packages

      @service
        header: 'Packages'
        name: 'shinken-scheduler'

## Configuration

      @file.ini
        header: 'Configuration'
        target: '/etc/shinken/daemons/schedulerd.ini'
        content: daemon: options.ini
        backup: true
        eof: true

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
