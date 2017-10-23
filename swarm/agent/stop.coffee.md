
# Stop Docker Swarm Agent Container

Stop the docker container using docker stop commande.

    module.exports = header: 'Swarm Agent Stop', handler: (options) ->
      @docker.stop
        docker: options.docker
        container: options.name
