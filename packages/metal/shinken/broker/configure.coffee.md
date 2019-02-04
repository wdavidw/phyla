
# Shinken Broker Configure

    module.exports = (service) ->
      options = service.options

## Identities

      options.user ?= merge {}, service.deps.commons.options.user, options.user
      options.group ?= merge {}, service.deps.commons.options.group, options.user

## Build Dir

      options.build_dir = service.deps.commons.options.build_dir

## Config

This configuration is used by arbiter to send the configuration when arbiter
synchronize configuration through network. The generated file must be on the
arbiter host.

      options.config ?= {}
      options.config.host ?= '0.0.0.0'
      options.config.port ?= 7772
      options.config.spare ?= '0'
      options.config.realm ?= 'All'
      # There can be only one.... broker with manage_arbiters
      options.config.manage_arbiters ?= if service.deps.broker[0].node.fqdn is service.node.fqdn then '1' else '0'
      options.config.modules = [options.config.modules] if typeof options.config.modules is 'string'
      options.config.modules ?= Object.keys options.modules if options.modules
      #Misc
      options.iptables ?= !!service.deps.iptables and service.deps.iptables?.options?.action is 'start'
      options.prepare ?= service.deps.broker[0].node.fqdn is service.node.fqdn
      options.fqdn ?= service.node.fqdn

## Nginx
      
      options.nginx_conf_dir ?= service.deps.nginx.options.conf_dir
      options.nginx_log_dir ?= service.deps.nginx.options.log_dir

## SSL

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
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
      options.ini.pidfile = '%(workdir)s/brokerd.pid'
      options.ini.local_log = '%(logdir)s/brokerd.log'
      options.ini.daemon_thread_pool_size ?= 16
      options.ini.max_queue_size ?= 100000

## Modules

      options.modules ?= {}
      # WebUI
      options.modules['webui2'] ?= {}
      options.modules['webui2'].version ?= '2.5.1'
      options.modules['webui2'].source ?= 'https://github.com/shinken-monitoring/mod-webui/archive/2.5.1.zip'
      options.modules['webui2'].archive ?= "mod-webui-#{options.modules['webui2'].version}"
      options.modules['webui2'].python_modules ?= {}
      options.modules['webui2'].python_modules.bottle ?= {}
      options.modules['webui2'].python_modules.bottle.version ?= '0.12.8'
      options.modules['webui2'].python_modules.bottle.url ?= 'https://pypi.python.org/packages/52/df/e4a408f3a7af396d186d4ecd3b389dd764f0f943b4fa8d257bfe7b49d343/bottle-0.12.8.tar.gz#md5=13132c0a8f607bf860810a6ee9064c5b'
      options.modules['webui2'].python_modules.pymongo ?= {}
      options.modules['webui2'].python_modules.pymongo.version ?= '3.4.0'
      options.modules['webui2'].python_modules.pymongo.url ?= 'https://pypi.python.org/packages/82/26/f45f95841de5164c48e2e03aff7f0702e22cef2336238d212d8f93e91ea8/pymongo-3.4.0.tar.gz#md5=aa77f88e51e281c9f328cea701bb6f3e'
      # options.modules['webui2'].python_modules.importlib ?= {}
      # options.modules['webui2'].python_modules.importlib.version ?= '1.0.4'
      options.modules['webui2'].python_modules.requests ?= {}
      options.modules['webui2'].python_modules.requests.version ?= '2.18.1'
      options.modules['webui2'].python_modules.requests.url ?= 'https://pypi.python.org/packages/2c/b5/2b6e8ef8dd18203b6399e9f28c7d54f6de7b7549853fe36d575bd31e29a7/requests-2.18.1.tar.gz#md5=40f723ed01dddeaf990d0609d073f021'
      options.modules['webui2'].python_modules.arrow ?= {}
      options.modules['webui2'].python_modules.arrow.version ?= '0.10.0'
      options.modules['webui2'].python_modules.arrow.url ?= 'https://pypi.python.org/packages/54/db/76459c4dd3561bbe682619a5c576ff30c42e37c2e01900ed30a501957150/arrow-0.10.0.tar.gz#md5=5d00592200050ad58284d45a4ee147c6'
      # options.modules['webui2'].python_modules['alignak-backend-client'] ?= {}
      # options.modules['webui2'].python_modules['alignak-backend-client'].version ?= '0.9.3'
      # options.modules['webui2'].python_modules['alignak-backend-client'].archive ?= "alignak_backend_client-#{options.modules['webui2'].python_modules['alignak-backend-client'].version}"
      options.modules['webui2'].python_modules.passlib ?= {}
      options.modules['webui2'].python_modules.passlib.version ?= '1.7.1'
      options.modules['webui2'].python_modules.passlib.url ?= 'https://pypi.python.org/packages/25/4b/6fbfc66aabb3017cd8c3bd97b37f769d7503ead2899bf76e570eb91270de/passlib-1.7.1.tar.gz#md5=254869dae3fd9f09f0746a3cb29a0b15'
      options.modules['webui2'].config ?= {}
      options.modules['webui2'].nginx ?= {}
      options.modules['webui2'].nginx.port ?= '7777'
      options.modules['webui2'].modules ?= {}
      options.modules['webui2'].config.host ?= if options.config.use_ssl is '1' then 'localhost' else '0.0.0.0'
      options.modules['webui2'].config.port ?= '7767'
      options.modules['webui2'].config.auth_secret ?= 'rybashinken123'
      options.modules['webui2'].config.htpasswd_file ?= '/etc/shinken/htpasswd.users'
      unless options.modules['webui2'].config.uri
        if service.deps.mongodb_router?.length > 0 then options.modules['webui2'].config.uri = "mongodb://#{service.deps.mongodb_router[0].node.fqdn}:#{service.deps.mongodb_router[0].options.net.port}/?safe=false"
        else throw Error 'No mongodb instance detected. Provide external uri (options.modules.webui2.config.uri) or install mongodb on the cluster'
      options.modules['webui2']['modules']['ui-graphite'] ?= {}
      options.modules['webui2']['modules']['ui-graphite'].type ?= 'graphite-webui'
      options.modules['webui2']['modules']['ui-graphite'].source ?= 'https://github.com/shinken-monitoring/mod-graphite/archive/2.1.2.zip'
      options.modules['webui2']['modules']['ui-graphite'].version ?= '2.1.2'
      options.modules['webui2']['modules']['ui-graphite'].config ?= {}
      options.modules['webui2']['modules']['ui-graphite'].config.uri ?= 'http://localhost:3080/'
      options.modules['webui2']['modules']['ui-graphite'].config.templates_path ?= "#{options.user.home}/share/templates/graphite/"
      options.modules['webui2']['modules']['ui-graphite'].config.graphite_data_source ?= 'shinken'
      options.modules['webui2']['modules']['ui-graphite'].config.dashboard_view_font ?= '8'
      options.modules['webui2']['modules']['ui-graphite'].config.dashboard_view_width ?= '320'
      options.modules['webui2']['modules']['ui-graphite'].config.dashboard_view_height ?= '240'
      options.modules['webui2']['modules']['ui-graphite'].config.detail_view_font ?= '10'
      options.modules['webui2']['modules']['ui-graphite'].config.detail_view_width ?= '786'
      options.modules['webui2']['modules']['ui-graphite'].config.detail_view_height ?= '308'
      options.modules['webui2']['modules']['ui-graphite'].config.color_warning ?= 'orange'
      options.modules['webui2']['modules']['ui-graphite'].config.color_critical ?= 'red'
      options.modules['webui2']['modules']['ui-graphite'].config.color_min ?= 'black'
      options.modules['webui2']['modules']['ui-graphite'].config.color_max ?= 'blue'
      # Logs
      options.modules['mongo-logs'] ?= {}
      options.modules['mongo-logs'].version ?= '1.2.0'
      options.modules['mongo-logs'].config ?= {}
      options.modules['mongo-logs'].config.services_filter ?= 'bi:>0'
      # Graphite
      options.modules['graphite2'] ?= {}
      options.modules['graphite2'].version ?= '2.1.4'
      options.modules['graphite2'].archive ?= "mod-graphite-#{options.modules['graphite2'].version}"
      options.modules['graphite2'].type ?= 'graphite_perfdata'
      options.modules['graphite2'].config ?= {}
      options.modules['graphite2'].config.host ?= 'localhost'
      options.modules['graphite2'].config.port ?= 2103
      options.modules['graphite2'].config.state_enable ?= '1'
      options.modules['graphite2'].config.state_host ?= '1'
      options.modules['graphite2'].config.state_service ?= '1'
      options.modules['graphite2'].config.graphite_data_source ?= 'shinken'
      # Livestatus
      options.modules['livestatus'] ?= {}
      options.modules['livestatus'].version ?= '1.4.2'
      options.modules['livestatus'].modules ?= {}
      options.modules['livestatus'].config ?= {}
      options.modules['livestatus'].config.host ?= '*'
      options.modules['livestatus'].config.port ?= '50000'
      options.modules['livestatus'].modules['logstore-null'] ?= {}
      options.modules['livestatus'].modules['logstore-null'].version ?= '1.4.1'
      options.modules['livestatus'].modules['logstore-null'].type ?= 'logstore_null'
      options.modules['livestatus'].modules['logstore-null'].config_file ?= 'logstore_null.cfg'
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
      for name, mod of options.modules then configmod name, mod

## Wait

      options.wait ?= {}
      options.wait.tcp ?= for srv in service.deps.broker
        host: srv.node.fqdn
        port: srv.options.config?.port or options.config.port

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
