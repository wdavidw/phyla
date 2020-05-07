
# MariaDB Server

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: '@rybajs/tools/ssl', local: true
        mariadb: module: './src/server'
      configure:
        './src/server/configure'
      commands:
        'check':
          './src/server/check'
        'install': [
          './src/server/install'
          './src/server/replication'
          './src/server/check'
        ]
        'stop':
          './src/server/stop'
        'start':
          './src/server/start'
