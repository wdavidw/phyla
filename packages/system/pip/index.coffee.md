
# Pip

Installs pip and given packages

    module.exports =
      configure:
        '@rybajs/system/pip/configure'
      commands:
        'install':
          '@rybajs/system/pip/install'