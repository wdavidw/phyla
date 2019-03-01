
# Ambari Repo

    module.exports =
      deps:
        ssl: module: '@rybajs/tools/ssl', local: true, auto: true, implicit: true
        java: module: '@rybajs/system/java', local: true, recommanded: true
      configure:
        '@rybajs/ambari/repo/configure'
      commands:
        'install':  [
          '@rybajs/ambari/repo/install'
        ]
