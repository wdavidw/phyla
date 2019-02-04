
# Hive HCatalog Backup

The backup script dumps the content of the configuration.

    module.exports =  header: 'Hive HCatalog Backup', handler: ({options}) ->

## Backup Configuration

Backup the active Hive configuration.

      @tools.backup
        header: 'Configuration'
        name: 'conf'
        source: options.conf_dir
        target: "/var/backups/hive/"
        interval: month: 1
        retention: count: 2

## Dependencies

    db = require '@nikitajs/core/lib/misc/db'
