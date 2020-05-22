
# Keycloak

[Keycloak][home]

Open Source Identity and Access Management


    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client'
        ipa_client: module: 'masson/core/freeipa/client', local: true
      configure:
        '@rybajs/metal/keycloak/configure'
      commands:
        'install': [
          '@rybajs/metal/keycloak/install'
          '@rybajs/metal/keycloak/start'
        ]

[home]: https://www.keycloak.org/
