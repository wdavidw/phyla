
# Shinken Commons

This module contains configuration, dependencies, and installation steps commons
to all shinken submodules

    module.exports =
      deps:
        ssl:  module: 'masson/core/ssl', local: true
        commons: module: 'ryba/shinken/commons'
      configure:
        'ryba/shinken/commons/configure'
      commands:
        'install':
          'ryba/shinken/commons/install'
        'prepare':
          'ryba/shinken/commons/prepare'
