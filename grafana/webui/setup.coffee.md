
# Prometheus Install

    module.exports = header: 'Grafana WEBUi Setup', handler: (options) ->
      beans = null
      rows = []
      exp = []

## Register

      @registry.register ['grafana', 'dashboard'], 'ryba/grafana/actions/grafana_dashboard'
      @registry.register ['grafana', 'datasource'], 'ryba/grafana/actions/grafana_datasource'

## Datasources

      @each options.datasources, (opts, callback) ->
        {key, value} = opts
        @grafana.datasource
          header: "#{key}"
          username: options.ini['security']['admin_user']
          password: options.ini['security']['admin_password']
          url: options.url
        , value
        @next callback

## Dashboards

      @each options.templates, (opts, callback) ->
        {key, value} = opts
        @grafana.dashboard
          username: options.ini['security']['admin_user']
          password: options.ini['security']['admin_password']
          url: options.url
        , value
        @next callback

## Dependencies

    quote = require 'regexp-quote'
    misc = require 'nikita/lib/misc'
    mkcmd = require '../../lib/mkcmd'
