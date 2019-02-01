
# Shinken Poller Configure

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

      options.user ?= merge {}, service.deps.commons.options.user, options.user
      options.group ?= merge {}, service.deps.commons.options.group, options.group
      # Add shinken to docker group
      options.user.groups ?= []
      options.user.groups.push service.deps.docker.options.group.name unless service.deps.docker.options.group.name in options.user.groups

## Config

This configuration is used by arbiter to send the configuration when arbiter
synchronize configuration through network. The generated file must be on the
arbiter host.

      options.config ?= {}
      options.config.host ?= '0.0.0.0'
      options.config.port ?= 7771
      options.config.spare ?= '0'
      options.config.realm ?= 'All'
      options.config.modules = [options.config.modules] if typeof options.config.modules is 'string'
      options.config.modules ?= Object.keys options.modules
      options.config.tags = [options.config.tags] if typeof options.config.tags is 'string'
      options.config.tags ?= []
      #Misc
      options.iptables ?= !!service.deps.iptables and service.deps.iptables?.options?.action is 'start'
      options.prepare ?= service.deps.poller[0].node.fqdn is service.node.fqdn
      options.fqdn ?= service.node.fqdn

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      throw Error "Kerberos Realm #{options.krb5.realm} not found in service.deps.krb5_client.options.admin" unless options.krb5.admin?
      options.krb5_principal ?= "#{options.user.name}/#{service.node.fqdn}@#{options.krb5.realm}"
      options.krb5_keytab ?= "/etc/security/keytabs/shinken.test.keytab"



## SSL

      options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      if options.ssl.enabled
        options.config['use_ssl'] ?= '1'
        options.config['hard_ssl_name_check'] ?= '1'
        throw Error 'Missing options.ssl.cacert' unless options.ssl.cacert
        throw Error 'Missing options.ssl.cert' unless options.ssl.cert
        throw Error 'Missing options.ssl.key' unless options.ssl.key
        options.tls_cert_file ?= "#{options.user.home}/resources/certs/cert.pem"
        options.tls_key_file ?= "#{options.user.home}/resources/certs/key.pem"
        throw Error 'TLS mode requires "tls_cert_file"' unless options.tls_cert_file
        throw Error 'TLS mode requires "tls_key_file"' unless options.tls_key_file
        # configure swarm keys
        options.credentials ?= {}
        options.credentials.swarm_user ?= {}
        options.credentials.swarm_user.key ?= "/home/#{options.user.name}/plugins/certs/key.pem"
        options.credentials.swarm_user.cert ?= "/home/#{options.user.name}/plugins/certs/cert.pem"
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
      options.ini.pidfile = '%(workdir)s/pollerd.pid'
      options.ini.local_log = '%(logdir)s/pollerd.log'

## Wait

      options.wait ?= {}
      options.wait.tcp ?= for srv in service.deps.poller
        host: srv.node.fqdn
        port: srv.options?.config?.port or options.config.port

## Dependencies

    {merge} = require '@nikita/core/lib/misc'
