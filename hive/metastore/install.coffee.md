
# Hive Metastore Install

    module.exports =  header: 'Hive Metastore Install', handler: ->
      {metastore} = @config.ryba.hive

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_upload', 'ryba/lib/hdfs_upload'

## SQL Connectors

      @call
        header: 'MySQL Client'
        if: metastore.db.engine is 'mysql'
      , ->
        @service
          name: 'mysql'
        @service
          name: 'mysql-connector-java'
      @call
        header: 'Postgres Client'
        if: metastore.db.engine is 'postgres'
      , ->
        @service
          name: 'postgresql'
        @service
          name: 'postgresql-jdbc'

## Metastore DB

      @call header: 'Metastore DB', ->
        @db.user metastore.db, database: null,
          header: 'User'
          if: metastore.db.engine in ['mysql', 'postgres']
        @db.database metastore.db,
          header: 'Database'
          user: metastore.db.username
          if: metastore.db.engine in ['mysql', 'postgres']
        @db.schema metastore.db,
          header: 'Schema'
          if: metastore.db.engine is 'postgres'
          schema: metastore.db.schema or metastore.db.database
          database: metastore.db.database
          owner: metastore.db.username
