
# Shinken Reactionner Configure

    module.exports = ->
      {shinken} = @config.ryba
      reactionner = shinken.reactionner ?= {}
      # Additionnal Modules to install
      reactionner.modules ?= {}
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
      for name, mod of reactionner.modules then configmod name, mod

## Config

This configuration is used by arbiter to send the configuration when arbiter
synchronize configuration through network. The generated file must be on the
arbiter host.

      reactionner.config ?={}
      reactionner.config.host ?= '0.0.0.0'
      reactionner.config.port ?= 7769
      reactionner.config.spare ?= '0'
      reactionner.config.realm ?= 'All'
      reactionner.config.modules = [reactionner.config.modules] if typeof reactionner.config.modules is 'string'
      reactionner.config.modules ?= Object.keys reactionner.modules
      reactionner.config.tags = [reactionner.config.tags] if typeof reactionner.config.tags is 'string'
      reactionner.config.tags ?= []
      reactionner.config.use_ssl ?= shinken.config.use_ssl
      reactionner.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check

## Ini

This configuration is used by local service to load preconfiguration that cannot
be set runtime by arbiter configuration synchronization.

      reactionner.ini ?= {}
      reactionner.ini[k] ?= v for k, v of shinken.ini
      reactionner.ini.host = reactionner.config.host
      reactionner.ini.port = reactionner.config.port
      reactionner.ini.pidfile = '%(workdir)s/reactionnerd.pid'
      reactionner.ini.local_log = '%(logdir)s/reactionnerd.log'
      reactionner.ini.daemon_thread_pool_size ?= 16
