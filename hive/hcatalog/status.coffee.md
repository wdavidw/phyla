
# Hive HCatalog Status

Check if the HCatalog is running. The process ID is located by default
inside "/var/run/hive-hcatalog/hive-hcatalog.pid".

    module.exports = header: 'Hive HCatalog Status', handler: ->
      @service.status
        name: 'hive-hcatalog-server'
