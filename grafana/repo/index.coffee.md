
# Grafana Repository

    module.exports =
      use: {}
      configure:
        'ryba/grafana/repo/configure'
      commands:
        'install':
          'ryba/grafana/repo/install'
        'prepare':
          'ryba/grafana/repo/prepare'
