
# Shinken Poller Configure

    module.exports = ->
      mon_ctxs = @contexts 'ryba/commons/monitoring'
      {docker, ssl} = @config
      {shinken} = @config.ryba
      # Add shinken to docker group
      shinken.user.groups ?= []
      shinken.user.groups.push docker.group.name unless docker.group.name in shinken.user.groups
      poller = shinken.poller ?= {}
      # Executor
      poller.executor ?= {}
      poller.executor.krb5 ?= {}
      poller.executor.krb5.principal ?= "#{shinken.user.name}/#{@config.host}@#{@config.ryba.realm}"
      poller.executor.krb5.keytab ?= "/etc/security/keytabs/shinken.test.keytab"
      if ssl.cert? and ssl.key?
        poller.executor.ssl = ssl
        poller.executor.ssl.cert.target ?= "#{shinken.user.home}/resources/certs/cert.pem"
        poller.executor.ssl.key.target ?= "#{shinken.user.home}/resources/certs/key.pem"
        for ctx in mon_ctxs
          ctx.config.ryba.monitoring ?= {}
          ctx.config.ryba.monitoring.credentials ?= {}
          ctx.config.ryba.monitoring.credentials.swarm_user ?= {}
          ctx.config.ryba.monitoring.credentials.swarm_user.key ?= "/home/#{shinken.user.name}/plugins/certs/key.pem"
          ctx.config.ryba.monitoring.credentials.swarm_user.cert ?= "/home/#{shinken.user.name}/plugins/certs/cert.pem"
      # Additionnal Modules to install
      poller.modules ?= {}
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
      for name, mod of poller.modules then configmod name, mod

## Config

This configuration is used by arbiter to send the configuration when arbiter
synchronize configuration through network. The generated file must be on the
arbiter host.

      poller.config ?= {}
      poller.config.host ?= '0.0.0.0'
      poller.config.port ?= 7771
      poller.config.spare ?= '0'
      poller.config.realm ?= 'All'
      poller.config.modules = [poller.config.modules] if typeof poller.config.modules is 'string'
      poller.config.modules ?= Object.keys poller.modules
      poller.config.tags = [poller.config.tags] if typeof poller.config.tags is 'string'
      poller.config.tags ?= []
      poller.config.use_ssl ?= shinken.config.use_ssl
      poller.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check

## Ini

This configuration is used by local service to load preconfiguration that cannot
be set runtime by arbiter configuration synchronization.

      poller.ini ?= {}
      poller.ini[k] ?= v for k, v of shinken.ini
      poller.ini.host = poller.config.host
      poller.ini.port = poller.config.port
      poller.ini.pidfile = '%(workdir)s/pollerd.pid'
      poller.ini.local_log = '%(logdir)s/pollerd.log'
