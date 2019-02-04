
# Grafana Repository

    module.exports =
      deps: {}
      configure:
        '@rybajs/metal/grafana/repo/configure'
      commands:
        'install':
          '@rybajs/metal/grafana/repo/install'
        'prepare':
          '@rybajs/metal/grafana/repo/prepare'
