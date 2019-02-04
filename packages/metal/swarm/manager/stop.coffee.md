
# Stop Docker Swarm Manager Container

Stop the docker container using docker stop command.

    module.exports = header: 'Swarm Manager Stop', handler: (options) ->
      @docker.stop
        docker: options.docker
        container: options.name
