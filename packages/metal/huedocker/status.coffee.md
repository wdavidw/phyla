
# Hue Status

Check if hue_server container is running

    module.exports = header: 'Hue Docker Status', handler: (options) ->

      @docker.status  container: options.container
