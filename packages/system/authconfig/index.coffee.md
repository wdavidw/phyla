
# Authconfig Intall

    module.exports =
      use:
        yum: module: 'masson/core/yum'
      configure:
        '@rybajs/system/authconfig/configure'
      commands:
        'install':
          '@rybajs/system/authconfig/install'
