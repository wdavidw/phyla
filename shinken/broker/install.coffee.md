
# Shinken Broker Install

    module.exports = header: 'Shinken Broker Install', handler: (options) ->

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  shinken-broker   | 7772  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: options.config.port, protocol: 'tcp', state: 'NEW', comment: 'Shinken Broker' }]
      if options.config.use_ssl is '1'
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: options.modules['webui2'].nginx.port, protocol: 'tcp', state: 'NEW', comment: 'NGINX Proxy for Shinken WebUI' }
      else
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: options.modules['webui2'].config.port, protocol: 'tcp', state: 'NEW', comment: 'Shinken WebUI' }
      for name, mod of options.modules
        continue if name is 'webui2'
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Broker #{name}" }
      @tools.iptables
        rules: rules
        if: options.iptables

## Packages

      @call header: 'Packages', ->
        @service name: 'shinken-broker'
        @service name: 'python-requests'
        @service name: 'python-arrow'
        @service name: 'python-devel'
        @service name: 'openldap-devel'

## Configuration

      @file.ini
        header: 'Configuration'
        target: '/etc/shinken/daemons/brokerd.ini'
        content: daemon: options.ini
        backup: true
        eof: true

## Modules

      @call header: 'Modules', ->
        installmod = (name, mod) =>
          @call header: name, unless_exec: "shinken inventory | grep #{name}", ->
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
        # We compute the module list only once because pip list can be very slow
        @system.execute
          cmd: "pip list > #{options.build_dir}/.piplist"
          shy: true
        install_dep = (k, v) =>
          @call header: k, unless_exec: "grep #{k} #{options.build_dir}/.piplist", ->
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
        @system.remove
          target: "#{options.build_dir}/.piplist"
          shy: true

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

## NGINX

      @call header: 'NGINX', handler: ->
        @file.render
          header: 'Configure'
          target: "#{options.nginx_conf_dir}/conf.d/shinken_webui.conf"
          source: "#{__dirname}/resources/nginx.conf.j2"
          local: true
          context: options
        @service.restart
          header: 'Restart'
          if: -> @status -1
          name: 'nginx'
