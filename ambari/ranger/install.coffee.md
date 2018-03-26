
# Ambari Nifi Install

    module.exports = header: 'Ambari Ranger Install', handler: (options) ->

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Package

      @service 'ranger-admin'
      @service 'ranger-usersync'
      @service 'ranger-storm-plugin'

## SSL

      @call header: 'SSL', retry: 0, if: options.ssl.enabled, ->
        @system.mkdir
          unless_exists: true
          target: path.dirname options.ssl.truststore.target
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        # Client: import certificate to all hosts
        # `keytool -list -v -keystore /etc/nifi/conf/truststore.jks -storepass NifiTruststore123-`
        @java.keystore_add
          keystore: options.ssl.truststore.target
          storepass: options.ssl.truststore.password
          caname: "hadoop_root_ca"
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local
          uid: options.user.name
          gid: options.group.name
          mode: 0o0644
        for hostname, cert of options.ssl.certs
          @java.keystore_add
            keystore: options.ssl.truststore.target
            storepass: options.ssl.truststore.password
            caname: "#{hostname}"
            cacert: "#{cert.source}"
            local: cert.local
        # Server: import certificates, private and public keys to hosts with a server
        # `keytool -list -v -keystore /etc/nifi/conf/keystore.jks -storepass NifiKeystore123-`
        @java.keystore_add
          keystore: options.ssl.keystore.target
          storepass: options.ssl.keystore.password
          key: options.ssl.key.source
          cert: options.ssl.cert.source
          keypass: options.ssl.keystore.keypass
          name: options.ssl.key.name
          local: options.ssl.key.local
          uid: options.user.name
          gid: options.group.name
          mode: 0o0600
        @java.keystore_add
          keystore: options.ssl.keystore.target
          storepass: options.ssl.keystore.password
          caname: "hadoop_root_ca"
          cacert: options.ssl.cacert.source
          local: options.ssl.cacert.local

## Dependencies

    path = require('path').posix
