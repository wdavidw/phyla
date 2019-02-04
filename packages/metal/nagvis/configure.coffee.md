
# NagVis configure

*   `nagvis.install_dir` (string)
    Installation directory
*   `nagvis.version` (string)
    NagVis version. Used to automatically set source
*   `nagvis.source` (string)
    URL path to the source. You should not have to change it.
*   `nagvis.port` (int)
    Nagvis port.

Example

```json
    "nagvis": {
      "install_dir": "/usr/local/nagvis",
      "version": "1.9"
      "livestatus_address": "host.mydomain:50000"
    }
```

    module.exports = (service) ->
      options = service.options
      options.install_dir ?= '/usr/local/nagvis'

## Shinken
configure bind address based if shinken broker is available (local) or not

      if service.deps.broker[0]?
        options.base_dir ?= service.deps.broker[0].options.user.home
        options.livestatus_address ?= "#{if service.deps.broker[0].node.fqdn is service.node.fqdn then '127.0.0.1' else service.node.fqdn}:#{service.deps.broker[0].options.modules['livestatus'].config.port}"
      throw Error 'Must declare shinken broker module, or manually specify options.base_dir and options.livestatus_address' unless options.base_dir? and options.livestatus_address?

## HTTPD

      options.httpd_user ?= service.deps.httpd.options.user
      options.httpd_group ?= service.deps.httpd.options.group

## Configuration

      options.version ?= '1.9-nightly'
      options.source ?= "https://www.options.org/share/nagvis-#{options.version}.tar.gz"
      options.shinken_integrate ?= false
      options.config ?= {}
      options.config.global ?= {}
      options.config.global.file_group ?= 'apache'
      options.config.paths ?= {}
      options.config.defaults ?= {}
      options.config.index ?= {}
      options.config.automap ?= {}
      options.config.global ?= {}
      options.config.wui ?= {}
      options.config.worker ?= {}
      options.config.backend_live_1 ?= {}
      options.config.backend_live_1.backendtype ?= "mklivestatus"
      options.config.backend_live_1.socket ?= "tcp:127.0.0.1:50000"
      options.config.backend_ndomy_1 ?= {}
      options.config.backend_ndomy_1.backendtype ?= "ndomy"
      options.config.states ?= {}
