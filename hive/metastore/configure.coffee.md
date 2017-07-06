
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
      metastore = @config.ryba.hive.metastore ?= {}

## Configure Database

Note, at the moment, only MySQL and PostgreSQL are supported.

      metastore.db ?= {}
      metastore.db.username ?= 'hive'
      throw Error "Required Property: hive.metastore.db.password" unless metastore.db.password
      if metastore.db.jdbc
        # Ensure the url host is the same as the one configured in config.ryba.db_admin
        jdbc = db.jdbc metastore.db.jdbc
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
        if pg_ctx then metastore.db.engine ?= 'postgres'
        else if my_ctx then metastore.db.engine ?= 'mysql'
        else if ma_ctx then metastore.db.engine ?= 'mysql'
        else metastore.db.engine ?= 'derby'
        metastore.db.database ?= 'hive'
        metastore.db.jdbc ?= "#{db_admin[metastore.db.engine].jdbc}/#{metastore.db.database}?createDatabaseIfNotExist=true"
        metastore.db[k] ?= v for k, v of db_admin[metastore.db.engine]

## Metastore site

These configurations will not be rendered into a configuration file but be imported
by metastore provider like HCatalog or HiveServer2 (local mode).

      metastore.site ?= {}
      metastore.site['javax.jdo.option.ConnectionURL'] ?= metastore.db.jdbc
      metastore.site['javax.jdo.option.ConnectionUserName'] ?= metastore.db.username
      metastore.site['javax.jdo.option.ConnectionPassword'] ?= metastore.db.password
      metastore.site['javax.jdo.option.ConnectionDriverName'] ?= metastore.db.java.driver

## Module Dependencies

    db = require 'nikita/lib/misc/db'
