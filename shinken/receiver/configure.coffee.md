
# Shinken Receiver Configure

    module.exports = ->
      {shinken} = @config.ryba
      receiver = shinken.receiver ?= {}
      # Additionnal Modules to install
      receiver.modules ?= {}
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
      for name, mod of receiver.modules then configmod name, mod

## Config

This configuration is used by arbiter to send the configuration when arbiter
synchronize configuration through network. The generated file must be on the
arbiter host.

      receiver.config ?= {}
      receiver.config.host ?= '0.0.0.0'
      receiver.config.port ?= 7773
      receiver.config.spare ?= '0'
      receiver.config.realm ?= 'All'
      receiver.config.modules = [receiver.config.modules] if typeof receiver.config.modules is 'string'
      receiver.config.modules ?= Object.keys receiver.modules
      receiver.config.use_ssl ?= shinken.config.use_ssl
      receiver.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check

## Ini

This configuration is used by local service to load preconfiguration that cannot
be set runtime by arbiter configuration synchronization.

      receiver.ini ?= {}
      receiver.ini[k] ?= v for k, v of shinken.ini
      receiver.ini.host = receiver.config.host
      receiver.ini.port = receiver.config.port
      receiver.ini.pidfile = '%(workdir)s/receiverd.pid'
      receiver.ini.local_log = '%(logdir)s/receiverd.log'
