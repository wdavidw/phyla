
# Grafana Configure
  
    module.exports = (service) ->
      service = migration.call @, service, 'ryba/grafana/webui', ['ryba', 'grafana', 'webui' ], require('nikita/lib/misc').merge require('.').use,
        ssl: key: ['ssl']
        db_admin: key: ['ryba', 'db_admin']
        grafana_webui: key: ['ryba', 'grafana', 'webui']
      @config.ryba.grafana ?= {}
      options = @config.ryba.grafana.webui = service.options

## Access

      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'grafana'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'grafana'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.system ?= true
      options.user.comment ?= 'Grafana User'
      options.user.groups ?= 'hadoop'
      options.user.gid ?= options.group.name
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= true

## Configure Database

Note, at the moment, only MariaDB, PostgreSQL and MySQL are supported.

      options.db ?= {}
      options.db.engine ?= service.use.db_admin.options.engine
      options.db = merge {}, service.use.db_admin.options[options.db.engine], options.db
      options.db.database ?= 'grafana'
      options.db.username ?= 'grafana'
      throw Error "Required Option: db.password" unless options.db.password

## Configuration
      
      # options.source ?= 'https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.5.2-1.x86_64.rpm'
      # options.download ?= service.use.grafana_webui[0].node.fqdn is service.node.fqdn
      options.log_dir ?= '/var/log/grafana'
      options.conf_dir ?= '/etc/grafana/conf'
      options.run_dir ?= '/var/run/grafana'
      # Misc
      options.fqdn ?= service.node.fqdn

# Environment

      options.env ?= {}
      options.env['GRAFANA_USER'] ?= options.user.name
      options.env['GRAFANA_GROUP'] ?= options.group.name
      options.env['GRAFANA_HOME'] ?= options.user.home
      options.env['LOG_DIR'] ?= options.log_dir
      options.env['PID_FILE_DIR'] ?= options.run_dir
      options.env['DATA_DIR'] ?= "#{options.user.home}/data"
      options.env['CONF_DIR'] ?= options.conf_dir
      options.env['CONF_FILE'] ?= "#{options.conf_dir}/grafana.ini"
      options.env['MAX_OPEN_FILES'] ?= options.user.limits.nofile
      options.env['PLUGINS_DIR'] ?= "#{options.user.home}/plugins"
      options.env['RESTART_ON_UPGRADE'] ?= 'true'

# SSL

      options.ssl = merge {}, service.use.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.use.ssl
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key

# Server Properties

      options.ini ?= {}
      #webui
      options.ini['server'] ?= {}
      options.ini['server']['protocol'] ?= if options.ssl.enabled then 'https' else 'http'
      options.ini['server']['http_port'] ?= '3000'
      options.ini['server']['domain'] ?= service.node.fqdn
      options.ini['server']['cert_file'] ?= "#{options.conf_dir}/cert.pem"
      options.ini['server']['cert_key'] ?= "#{options.conf_dir}/key.pem"
      #database
      options.ini['database'] ?= {}
      options.ini['database']['type'] ?= 'mysql' if options.db.engine in ['mysql','mariadb']
      options.ini['database']['host'] ?= "#{options.db.host}:#{options.db.port}"
      options.ini['database']['name'] ?= options.db.database
      options.ini['database']['user'] ?= options.db.username
      options.ini['database']['password'] ?= options.db.password

## Wait

      options.wait_db_admin = service.use.db_admin.options.wait
      options.wait ?= {}
      options.wait.http = for srv in service.use.grafana_webui
        host: srv.node.fqdn
        port: srv.options.ini['server']['http_port'] or options.ini['server']['http_port'] or 3000

## Dependencies

    migration = require 'masson/lib/migration'
    {merge} = require 'nikita/lib/misc'
