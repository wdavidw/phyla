
# Ambari Ranger UserSync

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: '@rybajs/tools/ssl', local: true, auto: true, implicit: true
        java: module: '@rybajs/system/java', local: true, recommanded: true
        ambari_agent: module: '@rybajs/ambari/agent', local: true, required: true
        ranger_admin: module: '@rybajs/ambari/components/ranger_admin', required: true, auto: true
      configure:
        '@rybajs/ambari/components/ranger_usersync/configure'
      commands:
        'install': [
          '@rybajs/ambari/components/ranger_usersync/install'
        ]
