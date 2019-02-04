
# Knox Client

    module.exports =
      deps:
        knox_server: module: '@rybajs/metal/knox/server'
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        ranger_knox: module: '@rybajs/metal/ranger/plugins/knox'
      configure:
        '@rybajs/metal/knox/client/configure'
      commands:
        'install': [
          '@rybajs/metal/knox/client/install'
          '@rybajs/metal/knox/client/check'
        ]
        'check':
          '@rybajs/metal/knox/client/check'
