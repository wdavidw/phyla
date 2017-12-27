
# Shinken Arbiter Configure

    module.exports = (service) ->
      options = service.options
      # Auto-discovery of Modules
      options.modules ?= {}
      configmod = (name, mod) =>
        if mod.version?
          mod.type ?= name
          mod.archive ?= "mod-#{name}-#{mod.version}"
          mod.format ?= 'zip'
          mod.source ?= "https://github.com/shinken-monitoring/mod-#{name}/archive/#{mod.version}.#{mod.format}"
          mod.config_file ?= "#{name}.cfg"
        mod.modules ?= {}
        mod.config ?= {}
        mod.config.modules = [mod.config.modules] if typeof mod.config.modules is 'string'
        mod.config.modules ?= Object.keys mod.modules
        mod.python_modules ?= {}
        for pyname, pymod of mod.python_modules
          pymod.format ?= 'tar.gz'
          pymod.archive ?= "#{pyname}-#{pymod.version}"
          pymod.url ?= "https://pypi.python.org/simple/#{pyname}/#{pymod.archive}.#{pymod.format}"
        for subname, submod of mod.modules then configmod subname, submod
      for name, mod of options.modules then configmod name, mod
      options.broker_hosts ?= service.deps.broker.map( (srv) -> srv.node.fqdn )

## Identities

      options.user ?= merge {}, service.deps.commons.options.user, options.user
      options.group ?= merge {}, service.deps.commons.options.group, options.user

## Credentials
      
      options.credentials ?= service.deps.monitoring.options.credentials
      for key in ['hostgroups', 'contactgroups', 'commands', 'realms', 'dependencies', 
        'escalations', 'timeperiods','hosts', 'services', 'contacts'
      ]
        options[key] ?= service.deps.monitoring.options[key]

## Build Dir

      options.build_dir = service.deps.commons.options.build_dir
      options.plugin_dir = service.deps.commons.options.plugin_dir

## Config

This configuration is used by arbiter to send the configuration when arbiter
synchronize configuration through network. The generated file must be on the
arbiter host.

      options.config ?= {}
      options.config.host ?= '0.0.0.0'
      options.config.port ?= 7770
      options.config.spare ?= '0'
      options.config.modules = [options.config.modules] if typeof options.config.modules is 'string'
      options.config.modules ?= Object.keys options.modules if options.modules
      options.config.distributed ?= service.deps.arbiter.length > 1
      options.config.hostname ?= options.fqdn
      options.config.user = options.user.name
      options.config.group = options.group.name
      #Misc
      options.iptables ?= !!service.deps.iptables and service.deps.iptables?.options?.action is 'start'
      options.prepare ?= service.deps.arbiter[0].node.fqdn is service.node.fqdn
      options.fqdn ?= service.node.fqdn

## SSL

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      if options.ssl.enabled
        options.config['use_ssl'] ?= '1'
        options.config['hard_ssl_name_check'] ?= '1'
        throw Error 'Missing options.ssl.cacert' unless options.ssl.cacert
        throw Error 'Missing options.ssl.cert' unless options.ssl.cert
        throw Error 'Missing options.ssl.key' unless options.ssl.key
        options.config['ca_cert'] ?= '/etc/shinken/certs/ca.pem'
        options.config['server_cert'] ?= '/etc/shinken/certs/cert.pem'
        options.config['server_key'] ?= '/etc/shinken/certs/key.pem'
      else
        options.config['use_ssl'] ?= '0'
        options.config['hard_ssl_name_check'] ?= '0'

## Shinken Modules Configuration
Gather all shinken's arbiter, scheduler, poller, broker modules to render

      options.arbiter_modules ?= options.modules if options.modules #to normalize config
      options.broker_modules ?= service.deps.broker[0].options.modules if service.deps.broker
      options.poller_modules ?= service.deps.poller[0].options.modules if service.deps.poller
      options.reactionner_modules ?= service.deps.reactionner[0].options.modules if service.deps.reactionner
      options.receiver_modules ?= service.deps.receiver[0].options.modules if service.deps.receiver
      options.scheduler_modules ?= service.deps.scheduler[0].options.modules if service.deps.scheduler

## Shinken Daemons Configuration
Gather all shinken's arbiter, scheduler, poller, broker daemons config to render.

      #arbiter
      options.arbiter_daemons ?= service.deps.arbiter.map( (srv) ->
        fqdn: srv.node.fqdn
        shortname: srv.node.hostname
        port: srv.options.config.port or options.config.port
        spare: srv.options.config.spare or (if options.config.spare is '0' then '1' else '0')
        modules: Object.keys srv.options.modules or Object.keys options.arbiter_modules
        use_ssl: srv.options.config.use_ssl or options.config.use_ssl
        hard_ssl_name_check: srv.options.config.hard_ssl_name_check or options.config.hard_ssl_name_check
      )
      #broker
      options.broker_daemons ?= service.deps.broker.map( (srv) ->
        fqdn: srv.node.fqdn
        shortname: srv.node.hostname
        port: srv.options.config.port
        spare: srv.options.config.spare
        modules: Object.keys srv.options.modules
        use_ssl: srv.options.config.use_ssl
        hard_ssl_name_check: srv.options.config.hard_ssl_name_check
        manage_arbiters: srv.options.config.manage_arbiters
        realm: srv.options.config.realm
      )
      #poller
      options.poller_daemons ?= service.deps.poller.map( (srv) ->
        fqdn: srv.node.fqdn
        shortname: srv.node.hostname
        port: srv.options.config.port
        spare: srv.options.config.spare
        modules: Object.keys srv.options.config.modules
        tags: srv.options.config.tags
        use_ssl: srv.options.config.use_ssl
        hard_ssl_name_check: srv.options.config.hard_ssl_name_check
        realm: srv.options.config.realm
      )
      #reactionner
      options.reactionner_daemons ?= service.deps.reactionner.map( (srv) ->
        fqdn: srv.node.fqdn
        shortname: srv.node.hostname
        port: srv.options.config.port
        spare: srv.options.config.spare
        modules: Object.keys srv.options.config.modules
        tags: srv.options.config.tags
        use_ssl: srv.options.config.use_ssl
        hard_ssl_name_check: srv.options.config.hard_ssl_name_check
        realm: srv.options.config.realm
      )
      #receiver
      options.receiver_daemons ?= service.deps.receiver.map( (srv) ->
        fqdn: srv.node.fqdn
        shortname: srv.node.hostname
        port: srv.options.config.port
        spare: srv.options.config.spare
        modules: Object.keys srv.options.config.modules
        use_ssl: srv.options.config.use_ssl
        hard_ssl_name_check: srv.options.config.hard_ssl_name_check
        realm: srv.options.config.realm
      )
      #scheduler
      options.scheduler_daemons ?= service.deps.scheduler.map( (srv) ->
        fqdn: srv.node.fqdn
        shortname: srv.node.hostname
        port: srv.options.config.port
        spare: srv.options.config.spare
        modules: Object.keys srv.options.modules
        use_ssl: srv.options.config.use_ssl
        hard_ssl_name_check: srv.options.config.hard_ssl_name_check
        realm: srv.options.config.realm
      )
            
## Wait

      options.wait ?= {}
      options.wait.tcp ?= for srv in service.deps.arbiter
        host: srv.node.fqdn
        port: srv.options.config.port or options.config.port

## Dependencies

    {merge} = require 'nikita/lib/misc'

