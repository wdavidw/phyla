
# Apt

Installs given apt packages

    module.exports =
      configure:
        '@rybajs/system/apt/configure'
      commands:
        'install':
          '@rybajs/system/apt/install'