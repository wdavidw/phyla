
# Zookeeper Client Configure

    module.exports = (service) ->
      options = service.options
      zookeeper_server_options = service.deps.zookeeper_server[0].options

## Environment

      options.conf_dir ?= '/etc/zookeeper/conf'

## Identities

      options.group = merge zookeeper_server_options.group, options.group
      options.hadoop_group = merge zookeeper_server_options.hadoop_group, options.hadoop_group
      options.user = merge zookeeper_server_options.user, options.user

## Configuration

      options.env ?= {}
      options.env['JAVA_HOME'] ?= zookeeper_server_options.env['JAVA_HOME']
      options.env['CLIENT_JVMFLAGS'] ?= '-Djava.security.auth.login.config=/etc/zookeeper/conf/zookeeper-client.jaas'
      options.zookeeper_quorum = for srv in service.deps.zookeeper_server
        continue unless srv.options.config['peerType'] is 'participant'
        "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"

## Wait
      
      options.wait_zookeeper_server ?= service.deps.zookeeper_server[0].options.wait

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
