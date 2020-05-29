
# MariaDB Server

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: '@rybajs/tools/ssl', local: true
        mariadb: module: './src/server'
      configure:
        'masson/commons/mariadb/server/configure'
      commands:
        'check':
          'masson/commons/mariadb/server/check'
        'install': [
          'masson/commons/mariadb/server/install'
          'masson/commons/mariadb/server/replication'
          'masson/commons/mariadb/server/check'
        ]
        'stop':
          'masson/commons/mariadb/server/stop'
        'start':
          'masson/commons/mariadb/server/start'
