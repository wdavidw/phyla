
# SSL/TLS Configure

## Example

```json
{ "ssl": {
    "cacert": "/path/to/remote/certificate_authority",
    "cert": "/path/to/remote/certificate",
    "key": "/path/to/remote/private_key"
} }
```

    module.exports = ({options, node, deps}) ->

## Normalisation

      options.cacert ?= {}
      options.cert ?= {}
      options.key ?= {}
      options.cacert = source: options.cacert, local: false if typeof options.cacert is 'string'
      options.cert = source: options.cert, local: false if typeof options.cert is 'string'
      options.key = source: options.key, local: false if typeof options.key is 'string'

## FreeIPA adapter

      if deps.freeipa
        options.cacert.source ?= deps.freeipa.options.ssl.cacert
        options.cacert.local ?= false
        options.cert.source ?= deps.freeipa.options.ssl.cert
        options.cert.local ?= false
        options.key.source ?= deps.freeipa.options.ssl.key
        options.key.local ?= false

## CA Certiticate

      if options.cacert?.target
        options.cacert.target = "ca.cert.pem" if options.cacert.target is true
        throw Error "Invalid Target" unless typeof options.cacert.target is 'string'
        options.cacert.target = path.resolve '/etc/security/certs', options.cacert.target

## Public Certificate

      if options.cert?.target
        options.cert.target = "#{node.hostname}.cert.pem" if options.cert.target is true
        throw Error "Invalid Target" unless typeof options.cert.target is 'string'
        options.cert.target = path.resolve '/etc/security/certs', options.cert.target
      options.cert.name ?= node.hostname

## Private Key

      if options.key?.target
        options.key.target = "#{node.hostname}.key.pem" if options.key.target is true
        throw Error "Invalid Target" unless typeof options.key.target is 'string'
        options.key.target = path.resolve '/etc/security/certs', options.key.target
      options.key.name ?= node.hostname

## FreeIPA Java cacert

Automatically insert the FreeIPA CA into the Java truststore in 
"/etc/pki/java/cacerts".

Note, it seems like FreeIPA is doing it for us. The CA certificate is 
registered in "/etc/pki/java/cacerts" under the name "<IPA_DOMAIN>ipaca".

      options.ipa_java_cacerts ?= {}
      options.ipa_java_cacerts.enabled ?= true
      options.ipa_java_cacerts.caname ?= 'ipa_cacert'
      options.ipa_java_cacerts.target ?= ' /usr/java/default/jre/lib/security/cacerts'
      options.ipa_java_cacerts.source ?= deps.freeipa.options.ssl.cacert
      options.ipa_java_cacerts.local ?= false
      options.ipa_java_cacerts.password ?= 'changeit'

## JKS Truststore

      options.truststore ?= {}
      options.truststore.enabled = false
      if options.truststore.enabled
        throw Error "Required Option: options.cacert" unless options.cacert
        options.truststore.target ?= path.resolve '/etc/security/jks', 'truststore.jks'
        options.truststore.caname ?= "ryba_root_ca"
        throw Error "Required options: options.truststore.password" unless options.truststore.password

## JKS Keystore

The final keystore object will look like:

```
{
  "target": "/etc/security/jks/keystore.jks",
  "name": "{current hostname}",
  "caname": "ryba_root_ca",
  "password": "{required user password}",
  "keypass": "{often same as password}"
}
```

To create the keystore, the certificate paths are retrieved from the "ssl"
option. 

In Tomcat servers, the key password must match the keystore password. This is confirmed by the 
[Tomcat documentation](https://tomcat.apache.org/tomcat-6.0-doc/ssl-howto.html#Prepare_the_Certificate_Keystore) 
which state: "You MUST use the same password here as was used for the keystore 
password itself. This is a restriction of the Tomcat implementation."

      options.keystore ?= {}
      options.keystore.enabled = false
      if options.keystore.enabled
        throw Error "Required Option: options.key" unless options.key
        throw Error "Required Option: options.cert" unless options.cert
        options.keystore.target ?= path.resolve '/etc/security/jks', 'keystore.jks'
        options.keystore.name ?= node.hostname
        options.keystore.caname ?= "ryba_root_ca"
        throw Error "Required options: options.keystore.password" unless options.keystore.password
        throw Error "Required options: options.keystore.keypass" unless options.keystore.keypass

## Dependencies

    path = require('path').posix
