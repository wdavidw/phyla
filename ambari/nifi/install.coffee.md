
# Ambari Nifi Install

    module.exports = header: 'Ambari Nifi Install', handler: (options) ->

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Package

      @service 'nifi'

## Toolkit

      @call header: 'Toolkit', ->
        @file.download
          header: "Download"
          source: options.toolkit.source
          target: path.resolve '/var/tmp', path.basename options.toolkit.source
        @tools.extract
          source: path.resolve '/var/tmp', path.basename options.toolkit.source
          target: options.toolkit.target

## Nifi SSL

      @call header: 'SSL', if: options.ssl.enabled, ->
        # Client: import certificate to all hosts
        # `keytool -list -v -keystore /etc/nifi/conf/truststore.jks -storepass NifiTruststore123-`
        @java.keystore_add
          keystore: options.ssl.truststore.target
          storepass: options.ssl.truststore.password
          caname: "hadoop_root_ca"
          cacert: "#{options.ssl.cacert.source}"
          local: options.ssl.cacert.local
          uid: options.user.name
          gid: options.group.name
          mode: 0o0644
        for hostname, cert of options.ssl.certs
          @java.keystore_add
            keystore: options.ssl.truststore.target
            storepass: options.ssl.truststore.password
            caname: cert.name
            cacert: cert.source
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
          local: options.ssl.cert.local
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

[sr]: http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.2.0/bk_Installing_HDP_AMB/content/_meet_minimum_system_requirements.html
