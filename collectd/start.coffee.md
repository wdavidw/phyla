
# Collectd Start
Uses rpm's package default systemd scripts.

    module.exports = header: 'Collectd Start', handler: (options) ->

## Packages

      @service.start name: 'collectd'
