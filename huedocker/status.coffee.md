
# Hue Status

Check if hue_server container is running

    module.exports = header: 'Hue Docker Status', handler: ->
      {hue_docker} = @config.ryba
      @docker_status
        container: hue_docker.container
