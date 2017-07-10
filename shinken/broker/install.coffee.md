
# Shinken Broker Install

    module.exports = header: 'Shinken Broker Install', handler: ->
      {shinken} = @config.ryba
      {broker} = @config.ryba.shinken

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-broker   | 7772  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: broker.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Broker" }]
      for name, mod of broker.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Broker #{name}" }
      @tools.iptables
        rules: rules
        if: @config.iptables.action is 'start'

## Packages

      @call header: 'Packages', ->
        @service name: 'shinken-broker'
        @service name: 'python-requests'
        @service name: 'python-arrow'

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
        for name, mod of broker.modules then installmod name, mod

## Python Modules

      @call header: 'Python Modules', ->
        install_dep = (k, v) => 
          @call unless_exec: "pip list | grep #{k}", ->
            @file.download
              source: v.url
              target: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
              cache_file: "#{v.archive}.#{v.format}"
              md5: v.md5
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
        for _, mod of broker.modules then for k,v of mod.python_modules then install_dep k, v

## Fix Groups View

Fix the hierarchical view in WebUI.
Could also be natively corrected in the next shinken version. (actually 2.4)

      @call header: 'Fix Groups View', ->
        for object in  ['host', 'service']
          @file
            target: "/usr/lib/python2.7/site-packages/shinken/objects/#{object}group.py"
            write: [
              match: new RegExp "'#{object}group_name': StringProp.*,$", 'm'
              replace:  "'#{object}group_name': StringProp(fill_brok=['full_status']), # RYBA\n        '#{object}group_members': StringProp(fill_brok=['full_status']),"
            ]
