
# Shinken Commons

This module contains configuration, dependencies, and installation steps commons
to all shinken submodules

    module.exports =
      deps:
        ssl:  module: 'masson/core/ssl', local: true
        commons: module: '@rybajs/metal/shinken/commons'
      configure:
        '@rybajs/metal/shinken/commons/configure'
      commands:
        'install':
          '@rybajs/metal/shinken/commons/install'
        'prepare':
          '@rybajs/metal/shinken/commons/prepare'
