
# grafana/webui Install

Grafan is a great WEB Ui to visualize metrics, and cluster operations data. it allow Users
to create dashboard and organize collected metrics.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        grafana_repo: module: 'ryba/grafana/repo'
        grafana_webui: module: 'ryba/grafana/webui'
      configure:
        'ryba/grafana/webui/configure'
      commands:
        install: [
          'ryba/grafana/webui/install'
          'ryba/grafana/webui/start'
          'ryba/grafana/webui/check'
        ]
        prepare:
          'ryba/grafana/webui/prepare'
