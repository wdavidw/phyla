
# Tranquility Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/druid/tranquility', ['ryba', 'druid', 'tranquility'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        druid: key: ['ryba', 'druid']
        druid_tranquility: key: ['ryba', 'druid', 'tranquility']
      @config.ryba.druid ?= {}
      options = @config.ryba.druid.tranquility = service.options

## identity

      options.group = merge {}, service.use.druid.options.group, options.group
      options.user = merge {}, service.use.druid.options.user, options.user

## Layout

      options.dir ?= '/opt/tranquility'
      options.pid_dir = service.use.druid.options.pid_dir

## Package

      options.version ?= "0.8.0"
      options.source ?= "http://static.druid.io/tranquility/releases/tranquility-distribution-#{druid.tranquility.version}.tgz"

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
