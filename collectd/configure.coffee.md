

# Collectd Configure

    module.exports = (service) ->
      options = service.options

## Configuration

      options.conf_dir ?= '/etc/collectd.d'

## Plugins
[Collectd plugins](https://collectd.org/wiki/index.php/Table_of_Plugins) are module
which extends collectd base functionnality, like add service to monitor, sending metrics...
For now ryba does only support network plugin type.
the variable `plugins`, should contains plugins with there properties, so ryba
can render the configuration files.

      options.plugins ?= {}
      for k, plugin  of options.plugins
        throw Error "Collectd does not support plugin type plugin.type: #{plugin.type}" unless plugin.type in [
          'write_http'
          'network'
        ]
      options.loads ?= ['disk']

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
