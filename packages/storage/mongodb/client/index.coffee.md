
# MongoDB Client

    module.exports =
      deps:
        locale: module: 'masson/core/locale', local: true, auto: true, implicit: true
        repo: module: '@rybajs/storage/mongodb/repo'
        config_servers: module: '@rybajs/storage/mongodb/configsrv'
      commands:
        'install':
          '@rybajs/storage/mongodb/client/install'
        'check':
          '@rybajs/storage/mongodb/client/checks'
