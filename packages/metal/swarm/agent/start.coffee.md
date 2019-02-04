
# Start Docker Swarm Agent Container

Start the docker container using docker start commande.

    module.exports = header: 'Swarm Agent Start', handler: (options) ->
      @connection.wait options.wait_manager.tcp

      @docker.start
        docker: options.docker
        container: options.name
