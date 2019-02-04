
# Collectd Stop
Uses rpm's package default systemd scripts.

    module.exports = header: 'Collectd Stop', handler: (options) ->

## Packages

      @service.stop 'collectd'
