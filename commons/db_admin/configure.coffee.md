
# DB Admin Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/hadoop/core', ['ryba'], require('nikita/lib/misc').merge require('.').use,
        mysql: key: ['mysql', 'server']
        mariadb: key: ['mariadb', 'server']
        postres: key: ['postgres', 'server']
      options = @config.ryba.db_admin ?= service.options
      
      options.engine ?= 'mysql'

## Mysql

      # Auto discovered configuration
      if service.use.mysql
        options.mysql ?= {}
        options.mysql.engine = 'mysql'
        options.mysql.java ?= {}
        options.mysql.java.driver = 'com.mysql.jdbc.Driver'
        options.mysql.java.datasource = 'com.mysql.jdbc.jdbc2.optional.MysqlConnectionPoolDataSource'
        options.mysql.hosts ?= service.use.mysql.map (srv) -> srv.node.fqdn
        options.mysql.host ?= options.mysql.hosts[0]
        options.mysql.admin_username ?= 'root'
        options.mysql.admin_password ?= service.use.mysql[0].options.admin_password
        options.mysql.port ?= service.use.mysql[0].options.my_cnf['mysqld']['port']
        url = options.mysql.hosts.map((host)-> "#{host}:#{options.mysql.port}").join(',')
        options.mysql.jdbc ?= "jdbc:mysql://#{url}"
      # Manual user configurattion
      else if service.use.mysql
        options.mysql.port ?= 3306
      if options.mysql
        throw Error 'admin_username must be provided for external mysql cluster' unless options.mysql.admin_username?
        throw Error 'admin_password must be provided for external mysql cluster' unless options.mysql.admin_password?

## MariaDB

      # Auto discovered configuration
      if service.use.mariadb
        options.mysql ?= {}
        options.mysql.engine = 'mysql'
        options.mysql.java ?= {}
        options.mysql.java.driver = 'com.mysql.jdbc.Driver'
        options.mysql.java.datasource = 'org.mariadb.jdbc.MariaDbDataSource'
        options.mysql.hosts ?= service.use.mariadb.map (srv) -> srv.node.fqdn
        options.mysql.host ?= options.mysql.hosts[0]
        options.mysql.admin_username ?= 'root'
        options.mysql.admin_password ?= service.use.mariadb[0].options.admin_password
        options.mysql.port ?= service.use.mariadb[0].options.my_cnf['mysqld']['port']
        url = options.mysql.hosts.map((host)-> "#{host}:#{options.mysql.port}").join(',')
        options.mysql.jdbc ?= "jdbc:mysql://#{url}"
      # Manual user configurattion
      else if service.use.mysql
        throw Error "Required Options: hosts" unless options.mysql.hosts
        options.mysql.host ?= options.mysql.hosts[0]
        options.mysql.port ?= 3306
        url = options.mysql.hosts.map((host)-> "#{host}:#{options.mysql.port}").join(',')
        options.mysql.jdbc ?= "jdbc:mysql://#{url}"
      if options.mysql
        throw Error 'admin_username must be provided for external mysql cluster' unless options.mysql.admin_username?
        throw Error 'admin_password must be provided for external mysql cluster' unless options.mysql.admin_password?

## PostgreSQL

      # Auto discovered configuration
      if service.use.postgres
        options.postgres ?= {}
        options.postgres.engine = 'postgres'
        options.postgres.java ?= {}
        options.postgres.java.datasource = 'org.postgresql.jdbc2.Jdbc2PoolingDataSource'
        options.postgres.java.driver = 'org.postgresql.Driver'
        options.postgres.hosts ?= service.use.postgres.map (srv) -> srv.node.fqdn
        options.postgres.host ?= options.postgres.hosts[0]
        options.postgres.admin_username ?= 'root'
        options.postgres.admin_password ?= service.use.postgres[0].options.password
        options.postgres.port ?= service.use.postgres[0].options.port
        url = options.postgres.hosts.map((host)-> "#{host}:#{options.postgres.port}").join(',')
        options.postgres.jdbc ?= "jdbc:postgresql://#{url}"
      # Manual user configurattion
      else if service.use.postgres
        throw Error "Required Options: hosts" unless options.postgres.hosts
        options.postgres.host ?= options.postgres.hosts[0]
        options.postgres.port ?= 5432
        url = options.postgres.hosts.map((host)-> "#{host}:#{options.postgres.port}").join(',')
        options.postgres.jdbc ?= "jdbc:postgresql://#{url}"
      if options.postgres
        throw Error 'Required Option: admin_username' unless options.postgres.admin_username?
        throw Error 'Required Option: admin_password' unless options.postgres.admin_password?

## Dependencies

    migration = require 'masson/lib/migration'
