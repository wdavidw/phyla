
# MongoDB Client

    module.exports =
      use:
        locale: module: 'masson/core/locale', local: true, auto: true, implicit: true
        repo: module: 'ryba/mongodb/repo'
        config_servers: module: 'ryba/mongodb/configsrv'
      configure:
        'ryba/mongodb/client/configure'
      commands:
        'install': ->
          options = @config.ryba.mongodb.client
          @call 'ryba/mongodb/client/install', options
        'check': ->
          options = @config.ryba.mongodb.client
          @call 'ryba/mongodb/client/checks', options
