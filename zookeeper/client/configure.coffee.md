
# Zookeeper Client Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/zookeeper/client', ['ryba', 'zookeeper_client'], require('nikita/lib/misc').merge require('.').use,
        java: key: ['java']
        krb5_client: key: ['krb5_client']
        test_user: key: ['ryba']
        hdp: key: ['ryba', 'hdp']
        zookeeper_server: key: ['ryba', 'zookeeper']
      options = @config.ryba.zookeeper_client = service.options
      zookeeper_server_options = service.use.zookeeper_server[0].options

## Environnment

      options.conf_dir ?= zookeeper_server_options.conf_dir

## Identities

      options.group = merge zookeeper_server_options.group, options.group
      options.hadoop_group = merge zookeeper_server_options.hadoop_group, options.hadoop_group
      options.user = merge zookeeper_server_options.user, options.user

## Configuration

      options.env ?= {}
      options.env['JAVA_HOME'] ?= zookeeper_server_options.env['JAVA_HOME']
      options.env['CLIENT_JVMFLAGS'] ?= '-Djava.security.auth.login.config=/etc/zookeeper/conf/zookeeper-client.jaas'
      options.zookeeper_quorum = for srv in service.use.zookeeper_server
        continue unless srv.options.config['peerType'] is 'participant'
        "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"

## Wait
      
      options.wait_zookeeper_server ?= service.use.zookeeper_server[0].options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
