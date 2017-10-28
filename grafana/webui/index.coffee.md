
# grafana/webui Install

Grafan is a great WEB Ui to visualize metrics, and cluster operations data. it allow Users
to create dashboard and organize collected metrics.

    module.exports =
      use:
        ssl: module: 'masson/core/ssl', local: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        grafana_webui: module: 'ryba/grafana/webui'
      configure:
        'ryba/grafana/webui/configure'
      commands:
        install: ->
          options = @config.ryba.grafana.webui
          @call 'ryba/grafana/webui/install', options
          @call 'ryba/grafana/webui/start', options
          @call 'ryba/grafana/webui/check', options
        prepare: ->
          options = @config.ryba.grafana.webui
          @call 'ryba/grafana/webui/prepare', options
