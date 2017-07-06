
# Hive Metastore Backup

The backup script dump the content of the hive database.

    module.exports =  header: 'Hive Metastore Backup', label_true: 'BACKUPED', handler: ->
      {metastore} = @config.ryba.hive

## Backup Database

      engines_cmd =
        mysql: "mysqldump -u#{metastore.db.username} -p#{metastore.db.password} -h#{metastore.db.hosts[0]} -P#{metastore.db.port} #{metastore.db.database}"
      throw Error 'Database engine not supported' unless engines_cmd[metastore.db.engine]
      @tools.backup
        label_true: 'BACKUPED'
        header: 'Backup Database'
        name: 'db'
        cmd: engines_cmd[jdbc.engine]
        target: "/var/backups/hive/"
        interval: month: 1
        retention: count: 2

## Dependencies

    db = require 'nikita/lib/misc/db'
