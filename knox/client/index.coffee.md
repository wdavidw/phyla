
# Knox Client

    module.exports =
      use:
        knox_server: module: 'ryba/knox/server'
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_knox: module: 'ryba/ranger/plugins/knox'
      configure:
        'ryba/knox/client/configure'
      commands:
        'install': ->
          options = @config.ryba.knox
          @call 'ryba/knox/client/install', options
          @call 'ryba/knox/client/check', options
        'check': ->
          options = @config.ryba.knox
          @call 'ryba/knox/client/check', options
