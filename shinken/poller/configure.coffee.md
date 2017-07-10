
# Shinken Poller Configure

    module.exports = ->
      {docker} = @config
      {shinken} = @config.ryba
      # Add shinken to docker group
      shinken.user.groups ?= []
      shinken.user.groups.push docker.group.name unless docker.group.name in shinken.user.groups
      poller = shinken.poller ?= {}
      # Executor
      poller.executor ?= {}
      poller.executor.krb5 ?= {}
      poller.executor.krb5.principal ?= "#{shinken.user.name}@#{@config.ryba.realm}"
      poller.executor.krb5.keytab ?= "/etc/security/keytabs/shinken.test.keytab"
      poller.executor.resources_dir ?= shinken.user.home
      # Python modules to install
      poller.python_modules ?= {}
      poller.python_modules.requests ?= {}
      poller.python_modules.requests.version ?= '2.18.1'
      poller.python_modules.kerberos ?= {}
      poller.python_modules.kerberos.version ?= '1.2.5'
      poller.python_modules.requests_kerberos ?= {}
      poller.python_modules.requests_kerberos.version ?= '0.7.0'
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
      # Config
      poller.config ?= {}
      poller.config.port ?= 7771
      poller.config.spare ?= '0'
      poller.config.realm ?= 'All'
      poller.config.modules = [poller.config.modules] if typeof poller.config.modules is 'string'
      poller.config.modules ?= Object.keys poller.modules
      poller.config.tags = [poller.config.tags] if typeof poller.config.tags is 'string'
      poller.config.tags ?= []
      poller.config.use_ssl ?= shinken.config.use_ssl
      poller.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
