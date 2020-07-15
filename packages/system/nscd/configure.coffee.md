
# nscd Configure

## Options

    module.exports = (service) ->
      options = service.options

## nscd properties

      options.properties ?= {}
      options.properties['server-user'] ?= 'nscd'
      options.properties['debug-level'] ?= '0'
      options.properties['paranoia'] ?= 'no'

      options.properties['enable-cache\thosts'] ?= 'yes'
      options.properties['positive-time-to-live\thosts'] ?= '3600'
      options.properties['negative-time-to-live\thosts'] ?= '20'
      options.properties['suggested-size\thosts'] ?= '211'
      options.properties['check-files\thosts'] ?= 'yes'
      options.properties['persistent\thosts'] ?= 'yes'
      options.properties['shared\thosts'] ?= 'yes'
      options.properties['max-db-size\thosts'] ?= '33554432'

      options.properties['enable-cache\tpasswd'] ?= 'no'
      options.properties['enable-cache\tgroup'] ?= 'no'
      options.properties['enable-cache\tnetgroup'] ?= 'no'
      options.properties['enable-cache\tservices'] ?= 'no'