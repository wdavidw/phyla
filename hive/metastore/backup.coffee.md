
# Hive Metastore Backup

The backup script dump the content of the hive database.

    module.exports =  header: 'Hive Metastore Backup', handler: ({options}) ->

## Backup Database

      engines_cmd =
        mysql: "mysqldump -u#{options.db.username} -p#{options.db.password} -h#{options.db.hosts[0]} -P#{options.db.port} #{options.db.database}"
      throw Error 'Database engine not supported' unless engines_cmd[options.db.engine]
      @tools.backup
        header: 'Backup Database'
        name: 'db'
        cmd: engines_cmd[jdbc.engine]
        target: "/var/backups/hive/"
        interval: month: 1
        retention: count: 2

## Dependencies

    db = require '@nikitajs/core/lib/misc/db'
