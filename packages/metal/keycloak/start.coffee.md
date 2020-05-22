
# Keycloak Start

Start the keycloak server. You can also start the server manually with the following
command:

```
service hue start
```

    module.exports = header: 'Keycloak Start', handler: ->
      @service.start name: 'keycloak'
