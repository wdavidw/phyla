
# HDP Repository

    module.exports =
      use: {}
      configure:
        'ryba/grafana/repo/configure'
      commands:
        'install': ->
          options = @config.ryba.grafana.repo
          @call 'ryba/grafana/repo/install', options
        'prepare': ->
          options = @config.ryba.grafana.repo
          @call 'ryba/grafana/repo/prepare', options
