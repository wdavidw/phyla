
# Knox Client

    module.exports =
      deps:
        knox_server: module: 'ryba/knox/server'
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_knox: module: 'ryba/ranger/plugins/knox'
      configure:
        'ryba/knox/client/configure'
      commands:
        'install': [
          'ryba/knox/client/install'
          'ryba/knox/client/check'
        ]
        'check':
          'ryba/knox/client/check'
