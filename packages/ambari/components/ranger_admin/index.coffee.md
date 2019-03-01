
# Ambari Ranger Admin

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: '@rybajs/tools/ssl', local: true, auto: true, implicit: true
        java: module: '@rybajs/system/java', local: true, recommanded: true
        ambari_agent: module: '@rybajs/ambari/agent'
      configure:
        '@rybajs/ambari/components/ranger_admin/configure'
      commands: {}
