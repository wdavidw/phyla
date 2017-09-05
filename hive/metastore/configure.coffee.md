
# Hive Metastore Configure

Metastore’s table abstraction presents users with a relational view of data in the Hadoop
distributed file system (HDFS) and ensures that users need not worry about where or in what
format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

## Configure

Example:

```json
{
  "ryba": {
    "hive": {
      "metastore": {
        "db": {
          "password": "hive123"
        }
      }
    }
  }
}
```

    module.exports = ->
      [pg_ctx] = @contexts 'masson/commons/postgres/server'
      [my_ctx] = @contexts 'masson/commons/mysql/server'
      [ma_ctx] = @contexts 'masson/commons/mariadb/server'
      hadoop_ctxs = @contexts ['ryba/hadoop/yarn_rm', 'ryba/hadoop/yarn_nm']
      {db_admin, realm} = @config.ryba
      @config.ryba.hive ?= {}
      options = @config.ryba.hive.metastore ?= {}

## Configure Database

Note, at the moment, only MySQL and PostgreSQL are supported.

      options.db ?= {}
      options.db.username ?= 'hive'
      throw Error "Required Options: db.password" unless options.db.password
      if options.db.jdbc
        # Ensure the url host is the same as the one configured in config.ryba.db_admin
        jdbc = db.jdbc options.db.jdbc
        switch jdbc.engine
          when 'mysql'
            admin = jdbc.addresses.filter (address) ->
              address.host in db_admin.mysql.hosts and "#{address.port}" is "#{db_admin.mysql.port}"
            throw new Error "Invalid host configuration" unless admin.length
          when 'postgresql'
            admin = jdbc.addresses.filter (address) ->
              address.host in db_admin.postgres.hosts and "#{address.port}" is "#{db_admin.postgres.port}"
            throw new Error "Invalid host configuration" unless admin.length
          else throw new Error 'Unsupported database engine'
      else
        if pg_ctx then options.db.engine ?= 'postgres'
        else if my_ctx then options.db.engine ?= 'mysql'
        else if ma_ctx then options.db.engine ?= 'mysql'
        else options.db.engine ?= 'derby'
        options.db.database ?= 'hive'
        options.db.jdbc ?= "#{db_admin[options.db.engine].jdbc}/#{options.db.database}?createDatabaseIfNotExist=true"
        options.db[k] ?= v for k, v of db_admin[options.db.engine]

## Configuration

These configurations will not be rendered into a configuration file but be imported
by metastore provider like HCatalog or HiveServer2 (local mode).

      options.site ?= {}
      options.site['javax.jdo.option.ConnectionURL'] ?= options.db.jdbc
      options.site['javax.jdo.option.ConnectionUserName'] ?= options.db.username
      options.site['javax.jdo.option.ConnectionPassword'] ?= options.db.password
      options.site['javax.jdo.option.ConnectionDriverName'] ?= options.db.java.driver

## Module Dependencies

    db = require 'nikita/lib/misc/db'
    migration = require 'masson/lib/migration'
