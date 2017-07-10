
# Shinken Broker Configure

    module.exports = ->
      {shinken} = @config.ryba
      broker = shinken.broker ?= {}
      # Additionnal modules to install
      broker.modules ?= {}
      # WebUI
      webui = broker.modules['webui2'] ?= {}
      webui.version ?= '2.5.1'
      webui.archive ?= "mod-webui-#{webui.version}"
      webui.python_modules ?= {}
      webui.python_modules.bottle ?= {}
      webui.python_modules.bottle.version ?= '0.12.8'
      webui.python_modules.pymongo ?= {}
      webui.python_modules.pymongo.version ?= '3.4.0'
      # webui.python_modules.importlib ?= {}
      # webui.python_modules.importlib.version ?= '1.0.4'
      webui.python_modules.requests ?= {}
      webui.python_modules.requests.version ?= '2.18.1'
      webui.python_modules.arrow ?= {}
      webui.python_modules.arrow.version ?= '0.10.0'
      # webui.python_modules['alignak-backend-client'] ?= {}
      # webui.python_modules['alignak-backend-client'].version ?= '0.9.3'
      # webui.python_modules['alignak-backend-client'].archive ?= "alignak_backend_client-#{webui.python_modules['alignak-backend-client'].version}"
      webui.python_modules.passlib ?= {}
      webui.python_modules.passlib.version ?= '1.7.1'
      webui.modules ?= {}
      webui.config ?= {}
      webui.config.host ?= '0.0.0.0'
      webui.config.port ?= '7767'
      webui.config.auth_secret ?= 'rybashinken123'
      webui.config.htpasswd_file ?= '/etc/shinken/htpasswd.users'
      uigraphite = webui.modules['ui-graphite'] ?= {}
      uigraphite.type ?= 'graphite-webui'
      uigraphite.version ?= "2.1.2"
      uigraphite.config ?= {}
      uigraphite.config.uri ?= 'http://localhost:3080/'
      uigraphite.config.templates_path ?= "#{shinken.user.home}/share/templates/graphite/"
      uigraphite.config.graphite_data_source ?= 'shinken'
      uigraphite.config.dashboard_view_font ?= '8'
      uigraphite.config.dashboard_view_width ?= '320'
      uigraphite.config.dashboard_view_height ?= '240'
      uigraphite.config.detail_view_font ?= '10'
      uigraphite.config.detail_view_width ?= '786'
      uigraphite.config.detail_view_height ?= '308'
      uigraphite.config.color_warning ?= 'orange'
      uigraphite.config.color_critical ?= 'red'
      uigraphite.config.color_min ?= 'black'
      uigraphite.config.color_max ?= 'blue'
      # Logs
      logs =  broker.modules['mongo-logs'] ?= {}
      logs.version ?= '1.2.0'
      logs.config ?= {}
      logs.config.services_filter ?= 'bi:>0'
      # Graphite
      graphite = broker.modules['graphite2'] ?= {}
      graphite.version ?= '2.1.4'
      graphite.archive ?= "mod-graphite-#{graphite.version}"
      graphite.type ?= 'graphite_perfdata'
      graphite.config ?= {}
      graphite.config.host ?= 'localhost'
      graphite.config.port ?= 2103
      graphite.config.state_enable ?= '1'
      graphite.config.state_host ?= '1'
      graphite.config.state_service ?= '1'
      graphite.config.graphite_data_source ?= 'shinken'
      # Livestatus
      livestatus = broker.modules['livestatus'] ?= {}
      livestatus.version ?= '1.4.2'
      livestatus.modules ?= {}
      livestatus.config ?= {}
      livestatus.config.host ?= '*'
      livestatus.config.port ?= '50000'
      logstore = livestatus.modules['logstore-null'] ?= {}
      logstore.version ?= '1.4.1'
      logstore.type ?= 'logstore_null'
      logstore.config_file ?= 'logstore_null.cfg'
      ## Auto discovery
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
      for name, mod of broker.modules then configmod name, mod
      # CONFIG
      broker.config ?= {}
      broker.config.port ?= 7772
      broker.config.spare ?= '0'
      broker.config.realm ?= 'All'
      # There can be only one.... broker with manage_arbiters
      broker.config.manage_arbiters ?= if @contexts('ryba/shinken/broker').map((ctx) -> ctx.config.host).indexOf(@config.host) is 0 then '1' else '0'
      broker.config.modules = [broker.config.modules] if typeof broker.config.modules is 'string'
      broker.config.modules ?= Object.keys broker.modules
      broker.config.use_ssl ?= shinken.config.use_ssl
      broker.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
