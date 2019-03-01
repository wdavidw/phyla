
# SSL Install 

    module.exports = header: 'SSL Install', handler: ({options}) ->

## Upload Certicate Authority

      @file
        header: 'CA'
        if: options.cacert?.target
      , options.cacert

## Upload Public Certicate

      @file
        header: 'Cert'
        if: options.cert?.target
      , options.cert

## Upload Private Key

      @file
        header: 'Key'
        if: options.key?.target
      , options.key

## FreeIPA Java cacert

      @java.keystore_add
        header: 'FreeIPA Java cacert'
        if: options.ipa_java_cacerts.enabled
        keystore: options.ipa_java_cacerts.target
        storepass: options.ipa_java_cacerts.password
        caname: options.ipa_java_cacerts.caname
        cacert: options.ipa_java_cacerts.source
        local: options.ipa_java_cacerts.local

## JKS

      @service
        header: 'OpenJDK'
        if: options.truststore.enabled or options.keystore.enabled
        name: 'java-1.8.0-openjdk-devel'
      # Client: import CA certificate
      @java.keystore_add
        header: 'Truststore'
        if: options.truststore.enabled
        keystore: options.truststore.target
        storepass: options.truststore.password
        caname: options.truststore.caname
        cacert: options.cacert.source
        local: options.cacert.local
        mode: 0o0644
        parent: mode: 0o0644
      # Server: import CA certificate, private and public keys
      @java.keystore_add
        header: 'Keystore'
        if: options.keystore.enabled
        keystore: options.keystore.target
        storepass: options.keystore.password
        caname: options.keystore.caname
        cacert: options.cacert.source
        key: options.key.source
        cert: options.cert.source
        keypass: options.keystore.keypass
        name: options.keystore.name
        local: options.cert.local
        mode: 0o0600
        parent: mode: 0o0644
