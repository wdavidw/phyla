
# Shinken Arbiter Install

    module.exports = header: 'Shinken Arbiter Install', handler: (options)->

## IPTables

| Service          | Port  | Proto | Parameter              |
|------------------|-------|-------|------------------------|
| shinken-arbiter  | 7770  |  tcp  |  options.config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [{ chain: 'INPUT', jump: 'ACCEPT', dport: options.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Arbiter" }]
      for name, mod of options.modules
        if mod.config?.port?
          rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: mod.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Arbiter #{name}" }
      @tools.iptables
        header: 'IPTables'
        rules: rules
        if: options.iptables

## Packages

      @service
        header: 'Packages'
        name: 'shinken-arbiter'

## Remove default config files

      @call header: 'Clean Install', ->
        @system.remove target: '/etc/shinken/realms/all.cfg'
        @system.remove target: '/etc/shinken/contacts/nagiosadmin.cfg'
        @system.remove target: '/etc/shinken/services/linux_disks.cfg'
        @system.remove target: '/etc/shinken/hosts/localhost.cfg'
        @system.remove target: '/etc/shinken/templates/templates.cfg'
        @system.remove target: '/etc/shinken/resource.d/path.cfg'
        
        @service.init
          header: 'Systemd Script'
          target: '/usr/lib/systemd/system/shinken-arbiter'
          source: "#{__dirname}/resources/shinken-arbiter-systemd.j2"
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

## Configuration

### Shinken Config

      @call header: 'Daemons Config', ->
        for subsrv in ['arbiter', 'broker', 'poller', 'reactionner', 'receiver', 'scheduler']
          @file.render
            header: subsrv
            target: "/etc/shinken/#{subsrv}s/#{subsrv}-master.cfg"
            source: "#{__dirname}/resources/#{subsrv}.cfg.j2"
            local: true
            context: "#{subsrv}s": options["#{subsrv}_daemons"]
            backup: true
        @file.properties
          target: '/etc/shinken/resource.d/resources.cfg'
          content:
            "$PLUGINSDIR$": options.plugin_dir
            "$DOCKER_EXEC$": 'docker exec poller-executor'
          backup: true
        @call
          header: 'Shinken CFG'
        , ->
          #now shinken throw error if empty configuration
          for k, v of options.config
            if Array.isArray v
              options.config[k] = '0' if v.length is 0
          writes = for k, v of options.config
            match: ///^#{k}=.*$///mg
            replace: "#{k}=#{v}"
            append: true
          @file
            target: '/etc/shinken/shinken.cfg'
            write: writes
            backup: true
            eof: true

### Modules Config

      @call header: 'Modules Config', ->
        config_mod = (name, mod) =>
          @file.render
            target: "/etc/shinken/modules/#{mod.config_file}"
            source: "#{__dirname}/resources/module.cfg.j2"
            local: true
            context:
              name: name
              type: mod.type
              config: mod.config
            backup: true
          if mod.modules?
            config_mod sub_name, sub_mod for sub_name, sub_mod of mod.modules
        # Loop on all services
        for service in ['arbiter', 'broker', 'poller', 'reactionner', 'receiver', 'scheduler']
          for name, mod of options["#{service}_modules"]
            config_mod name, mod

### Objects Config

Objects config

      @call header: 'Objects', ->
        # Un-templated objects
        ## Some commands need the lists of brokers (for their livestatus module)
        #for obj in ['hostgroups', 'servicegroups', 'contactgroups', 'commands', 'realms', 'dependencies', 'escalations', 'timeperiods']
        for obj in ['hostgroups', 'contactgroups', 'commands', 'realms', 'dependencies', 'escalations', 'timeperiods']
          @file.render
            header: obj
            target: "/etc/shinken/#{obj}/#{obj}.cfg"
            source: "#{__dirname}/../../commons/monitoring/resources/#{obj}.cfg.j2"
            local: true
            context:
              "#{obj}": options[obj]
              brokers: options.broker_hosts.join(',')
              credentials: options.credentials
            backup: true
        # Templated objects
        for obj in ['hosts', 'services', 'contacts']
          real = {}
          templated = {}
          for k, v of options[obj]
            if "#{v.register}" is '0' then templated[k] = v
            else real[k] = v
          @file.render
            header: "#{obj} templates"
            target: "/etc/shinken/templates/#{obj}.cfg"
            source: "#{__dirname}/../../commons/monitoring/resources/#{obj}.cfg.j2"
            local: true
            context: "#{obj}": templated
            backup: true
          @file.render
            header: obj
            target: "/etc/shinken/#{obj}/#{obj}.cfg"
            source: "#{__dirname}/../../commons/monitoring/resources/#{obj}.cfg.j2"
            local: true
            context: "#{obj}": real
            backup: true

## SSL


      @call header: 'SSL', if: options.ssl.enabled
      , ->
        @file.download
          source: options.ssl.cert.source
          target: options.config['server_cert']
          local: options.ssl.cert.local
          uid: options.user.name
          gid: options.group.name
        @file.download
          source: options.ssl.key.source
          target: options.config['server_key']
          local: options.ssl.key.local
          uid: options.user.name
          gid: options.group.name
        @file.download
          source: options.ssl.cacert.source
          target: options.config['ca_cert']
          local: options.ssl.cacert.local
          uid: options.user.name
          gid: options.group.name

## Check Config

This will execute a dry-run: arbiter will only check the configuration and exit
This output is more verbose than a failed start so it runs at the end of install

      @system.execute
        header: 'Check config'
        cmd: 'shinken-arbiter -v -r -c /etc/shinken/shinken.cfg'
        shy: true
