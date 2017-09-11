
# Hive HCatalog Backup

The backup script dumps the content of the configuration.

    module.exports =  header: 'Hive HCatalog Backup', label_true: 'BACKUPED', handler: (options) ->

## Backup Configuration

Backup the active Hive configuration.

      @tools.backup
        header: 'Configuration'
        label_true: 'BACKUPED'
        name: 'conf'
        source: options.conf_dir
        target: "/var/backups/hive/"
        interval: month: 1
        retention: count: 2

## Dependencies

    db = require 'nikita/lib/misc/db'
