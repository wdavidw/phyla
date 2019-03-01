
# Hive Metastore Configure

Metastore’s table abstraction presents users with a relational view of data in the Hadoop
distributed file system (HDFS) and ensures that users need not worry about where or in what
format their data is stored — RCFile format, text files, SequenceFiles, or ORC files.

## Example

```json
{
  "db": {
    "password": "hive123"
  }
}
```

    module.exports = (service) ->
      options = service.options

## Configure Database

Note, at the moment, only MariaDB, PostgreSQL and MySQL are supported.

      options.db ?= {}
      options.db.engine ?= service.deps.db_admin.options.engine
      options.db = mixme service.deps.db_admin.options[options.db.engine], options.db
      options.db.database ?= 'hive'
      options.db.username ?= 'hive'
      options.db.jdbc += "/#{options.db.database}?createDatabaseIfNotExist=true"
      throw Error "Required Option: db.password" unless options.db.password
      
      # if options.db.jdbc
      #   # Ensure the url host is the same as the one configured in config.ryba.db_admin
      #   jdbc = db.jdbc options.db.jdbc
      #   switch jdbc.engine
      #     when 'mysql'
      #       admin = jdbc.addresses.filter (address) ->
      #         address.host in db_admin.mysql.hosts and "#{address.port}" is "#{db_admin.mysql.port}"
      #       throw new Error "Invalid host configuration" unless admin.length
      #     when 'postgresql'
      #       admin = jdbc.addresses.filter (address) ->
      #         address.host in db_admin.postgres.hosts and "#{address.port}" is "#{db_admin.postgres.port}"
      #       throw new Error "Invalid host configuration" unless admin.length
      #     else throw new Error 'Unsupported database engine'
      # else
      #   if pg_ctx then options.db.engine ?= 'postgresql'
      #   else if my_ctx then options.db.engine ?= 'mysql'
      #   else if ma_ctx then options.db.engine ?= 'mysql'
      #   else options.db.engine ?= 'derby'
      #   options.db.database ?= 'hive'
      #   options.db.jdbc ?= "#{db_admin[options.db.engine].jdbc}/#{options.db.database}?createDatabaseIfNotExist=true"
      #   options.db[k] ?= v for k, v of db_admin[options.db.engine]

## Configuration

These configurations will not be rendered into a configuration file but be imported
by metastore provider like HCatalog or HiveServer2 (local mode).

Note, password can be removed from the configuration and placed inside a [CEKS
keystore file](https://cwiki.apache.org/confluence/display/Hive/AdminManual+Configuration#AdminManualConfiguration-RemovingHiveMetastorePasswordfromHiveConfiguration).

      options.hive_site ?= {}
      options.hive_site['javax.jdo.option.ConnectionURL'] ?= options.db.jdbc
      options.hive_site['javax.jdo.option.ConnectionUserName'] ?= options.db.username
      options.hive_site['javax.jdo.option.ConnectionPassword'] ?= options.db.password
      options.hive_site['javax.jdo.option.ConnectionDriverName'] ?= options.db.java.driver

## Module Dependencies

    db = require '@nikitajs/core/lib/misc/db'
    mixme = require 'mixme'
