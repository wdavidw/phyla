
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
      # Config
      receiver.config ?= {}
      receiver.config.port ?= 7773
      receiver.config.spare ?= '0'
      receiver.config.realm ?= 'All'
      receiver.config.modules = [receiver.config.modules] if typeof receiver.config.modules is 'string'
      receiver.config.modules ?= Object.keys receiver.modules
      receiver.config.use_ssl ?= shinken.config.use_ssl
      receiver.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
