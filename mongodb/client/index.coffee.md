
# MongoDB Client

    module.exports =
      deps:
        locale: module: 'masson/core/locale', local: true, auto: true, implicit: true
        repo: module: 'ryba/mongodb/repo'
        config_servers: module: 'ryba/mongodb/configsrv'
      configure:
        'ryba/mongodb/client/configure'
      commands:
        'install':
          'ryba/mongodb/client/install'
        'check':
          'ryba/mongodb/client/checks'
