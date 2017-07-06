
# Hive HCatalog Backup

The backup script dumps the content of the configuration.

    module.exports =  header: 'Hive HCatalog Backup', label_true: 'BACKUPED', handler: ->
      {hive} = @config.ryba
      user = hive.hcatalog.site['javax.jdo.option.ConnectionUserName']
      password = hive.hcatalog.site['javax.jdo.option.ConnectionPassword']
      jdbc = db.jdbc hive.hcatalog.site['javax.jdo.option.ConnectionURL']

## Backup Configuration

Backup the active Hive configuration.

      @tools.backup
        header: 'Configuration'
        label_true: 'BACKUPED'
        name: 'conf'
        source: hive.hcatalog.conf_dir
        target: "/var/backups/hive/"
        interval: month: 1
        retention: count: 2

## Dependencies

    db = require 'nikita/lib/misc/db'
