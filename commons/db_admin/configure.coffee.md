
# DB Admin Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/hadoop/core', ['ryba'], require('nikita/lib/misc').merge require('.').use,
        mysql: key: ['mysql', 'server']
        mariadb: key: ['mariadb', 'server']
        postres: key: ['postgres', 'server']
      options = @config.ryba.db_admin = service.options

## Engine

Default engine based on service discovery. The option "engine" is set if a
suitable database is found and match a pre-configured provider. Possible values 
are 'mariadb', 'postgresql' and 'mysql' in this order of preference.

For exemple, an "engine" options set to "mariadb" reflect the discovery of an
instance of MariaDB and the existance of a usable db object available as the
"mariadb" option.

      if service.use.mariadb
        options.engine ?= 'mariadb'
      else if service.use.postgresql
        options.engine ?= 'mariadb'
      else if service.use.mysql
        options.engine ?= 'mariadb'
      else
        options.engine ?= null

## Providers

A provider object contains commons properties and potentially database specific
properties. Commons properties are:

* `engine` (string)   
  One of the supported engine between "mariadb", "postgresql", "mysql", required.
* `admin_username` (string)   
  Administrator username.
* `admin_password` (string)   
  Administrator password.
* `java.driver` (string)   
  Java driver.
* `java.datasource` (string)   
  Java datasource.
* `jdbc` (string)   
  JDBC URL.
* `fqdns` ([string])   
  List of database FQDNs.
* `host` ([string])   
  Single database host for customers which doesn't support multi hosts or if a 
  proxy is configured.
* `port` (int)   
  Database server port.

### MariaDB

      # Auto discovered configuration
      if service.use.mariadb
        options.mariadb ?= {}
        options.mariadb.discovered = true
        options.mariadb.engine = 'mariadb'
        options.mariadb.admin_username ?= 'root'
        options.mariadb.admin_password ?= service.use.mariadb[0].options.admin_password
        options.mariadb.fqdns ?= service.use.mariadb.map (srv) -> srv.node.fqdn
        options.mariadb.host ?= options.mariadb.fqdns[0]
        options.mariadb.port ?= service.use.mariadb[0].options.my_cnf['mysqld']['port']
      # Manual configurattion
      else if options.mariadb
        throw Error "Required Options: fqdns" unless options.mariadb.fqdns
      # Default value of auto discovered and manual configurattion
      if options.mariadb
        options.mariadb.java ?= {}
        options.mariadb.java.driver = 'com.mysql.jdbc.Driver'
        options.mariadb.java.datasource = 'org.mariadb.jdbc.MariaDbDataSource'
        options.mariadb.port ?= 3306
        url = options.mariadb.fqdns.map((fqdn)-> "#{fqdn}:#{options.mariadb.port}").join(',')
        options.mariadb.jdbc ?= "jdbc:mysql://#{url}"
      if options.mariadb
        throw Error 'Required Option: mariadb.admin_username' unless options.mariadb.admin_username?
        throw Error 'Required Option: mariadb.admin_password' unless options.mariadb.admin_password?

### PostgreSQL

      # Auto discovered configuration
      if service.use.postgresql
        options.postgresql ?= {}
        options.postgresql.discovered = true
        options.postgresql.engine = 'postgresql'
        options.postgresql.admin_username ?= 'root'
        options.postgresql.admin_password ?= service.use.postgresql[0].options.password
        options.postgresql.fqdns ?= service.use.postgresql.map (srv) -> srv.node.fqdn
        options.postgresql.host ?= options.postgresql.fqdns[0]
        options.postgresql.port ?= service.use.postgresql[0].options.port
        url = options.postgresql.fqdns.map((fqdn)-> "#{fqdn}:#{options.postgresql.port}").join(',')
        options.postgresql.jdbc ?= "jdbc:postgresql://#{url}"
      # Manual configurattion
      else if options.postgresql
        throw Error "Required Options: fqdns" unless options.postgresql.fqdns
      # Default value of auto discovered and manual configurattion
      if options.postgresql
        options.postgresql.java ?= {}
        options.postgresql.java.datasource = 'org.postgresql.jdbc2.Jdbc2PoolingDataSource'
        options.postgresql.java.driver = 'org.postgresql.Driver'
        options.postgresql.port ?= 5432
        url = options.postgresql.fqdns.map((fqdn)-> "#{fqdn}:#{options.postgresql.port}").join(',')
        options.postgresql.jdbc ?= "jdbc:postgresql://#{url}"
      if options.postgresql
        throw Error 'Required Option: postgresql.admin_username' unless options.postgresql.admin_username?
        throw Error 'Required Option: postgresql.admin_password' unless options.postgresql.admin_password?

### Mysql

      # Auto discovered configuration
      if service.use.mysql
        options.mysql ?= {}
        options.mysql.discovered = true
        options.mysql.engine = 'mysql'
        options.mysql.admin_username ?= 'root'
        options.mysql.admin_password ?= service.use.mysql[0].options.admin_password
        options.mysql.fqdns ?= service.use.mysql.map (srv) -> srv.node.fqdn
        options.mysql.host ?= options.mysql.fqdns[0]
        options.mysql.port ?= service.use.mysql[0].options.my_cnf['mysqld']['port']
      # Manual configurattion
      else if options.postgresql
        throw Error "Required Options: fqdns" unless options.postgresql.fqdns
      # Default value of auto discovered and manual configurattion
      if options.mysql
        options.mysql.java.driver = 'com.mysql.jdbc.Driver'
        options.mysql.java.datasource = 'com.mysql.jdbc.jdbc2.optional.MysqlConnectionPoolDataSource'
        options.mysql.port ?= 3306
        options.mysql.java ?= {}
        url = options.mysql.fqdns.map((fqdn)-> "#{fqdn}:#{options.mysql.port}").join(',')
        options.mysql.jdbc ?= "jdbc:mysql://#{url}"
      if options.mysql
          throw Error 'Required Option: mysql.admin_username' unless options.mysql.admin_username?
          throw Error 'Required Option: mysql.admin_password' unless options.mysql.admin_password?

## Wait

      options.wait_mariadb = service.use.wait_mariadb[0].options.wait if service.use.wait_mariadb
      options.wait_postgresql = service.use.postgresql[0].options.wait if service.use.postgresql
      options.wait_mysql = service.use.mysql[0].options.wait if service.use.mysql
      options.wait = {}
      options.wait.tcp = []
      if options.mariadb then for fqdn in options.mariadb.fqdns
        options.wait.tcp.push host: fqdn, port: options.mariadb.port
      if options.postgresql then for fqdn in options.postgresql.fqdns
        options.wait.tcp.push host: fqdn, port: options.postgresql.port
      if options.mysql then for fqdn in options.mysql.fqdns
        options.wait.tcp.push host: fqdn, port: options.mysql.port

## Dependencies

    migration = require 'masson/lib/migration'
