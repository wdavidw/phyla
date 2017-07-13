
# Shinken Commons

This module contains configuration, dependencies, and installation steps commons
to all shinken submodules

    module.exports =
      use:
        ssl: implicit: true, module: 'masson/core/ssl'
      configure:
        'ryba/shinken/commons/configure'
      commands:
        'install':
          'ryba/shinken/commons/install'
