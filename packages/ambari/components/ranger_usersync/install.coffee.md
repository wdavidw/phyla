
# Ambari Ranger UserSync Install

    module.exports = header: 'Ambari Ranger UserSync Install', handler: ({options}) ->

## SSL

      @call header: 'SSL', retry: 0, ->
        @java.keystore_add
          header: 'Truststore CA'
          keystore: options.config['ranger.usersync.truststore.file']
          storepass: options.config['ranger.usersync.truststore.password']
          caname: "hadoop_root_ca"
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local
        # Server: import certificates, private and public keys to hosts with a server
        @java.keystore_add
          header: 'Keystore cert and key'
          keystore: options.config['ranger.usersync.keystore.file']
          storepass: options.config['ranger.usersync.keystore.password']
          key: "#{options.ssl.key.source}"
          cert: "#{options.ssl.cert.source}"
          keypass:options.config['ranger.usersync.keystore.password']
          name: "#{options.ssl.key.name}"
          local: options.ssl.key.local
          uid: options.user.name
          gid: options.group.name
        @java.keystore_add
          header: 'Keystore CA'
          keystore: options.config['ranger.usersync.keystore.file']
          storepass: options.config['ranger.usersync.keystore.password']
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: options.ssl.cacert.local
          uid: options.user.name
          gid: options.group.name
