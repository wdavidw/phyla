
# Shinken Scheduler Configure

    module.exports = (service) ->
      options = service.options
      # Additionnal Modules to install
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

## Identities

      options.user ?= mixme service.deps.commons.options.user, options.user
      options.group ?= mixme service.deps.commons.options.group, options.user

## Build Dir

      options.build_dir = service.deps.commons.options.build_dir

## Config

This configuration is used by arbiter to send the configuration when arbiter
synchronize configuration through network. The generated file must be on the
arbiter host.

      options.config ?= {}
      options.config.host ?= '0.0.0.0'
      options.config.port ?= 7768
      options.config.spare ?= '0'
      options.config.realm ?= 'All'
      options.config.modules = [options.config.modules] if typeof options.config.modules is 'string'
      options.config.modules ?= Object.keys options.modules
      #Misc
      options.iptables ?= !!service.deps.iptables and service.deps.iptables?.options?.action is 'start'
      options.prepare ?= service.deps.scheduler[0].node.fqdn is service.node.fqdn
      options.fqdn ?= service.node.fqdn

## SSL

      options.ssl = mixme service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      if options.ssl.enabled
        options.config['use_ssl'] ?= '1'
        options.config['hard_ssl_name_check'] ?= '1'
        throw Error 'Missing options.ssl.cacert' unless options.ssl.cacert
        throw Error 'Missing options.ssl.cert' unless options.ssl.cert
        throw Error 'Missing options.ssl.key' unless options.ssl.key
      else
        options.config['use_ssl'] ?= '0'
        options.config['hard_ssl_name_check'] ?= '0'

## Ini

This configuration is used by local service to load preconfiguration that cannot
be set runtime by arbiter configuration synchronization.

      options.ini ?= {}
      options.ini[k] ?= v for k, v of service.deps.commons.options.ini
      options.ini.host = options.config.host
      options.ini.port = options.config.port
      options.ini.pidfile = '%(workdir)s/schedulerd.pid'
      options.ini.local_log = '%(logdir)s/schedulerd.log'

## Wait

      options.wait ?= {}
      options.wait.http = for srv in service.deps.scheduler
        host: srv.node.fqdn
        port: srv.options.config?.port or options.config.port

## Dependencies

    mixme = require 'mixme'
