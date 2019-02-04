
# Start Docker Swarm Manager Container

Start the docker container using docker start command.

    module.exports = header: 'Swarm Manager Start', handler: (options) ->
      @call once: true, '@rybajs/metal/zookeeper/server/wait', options.wait_zookeeper
      @docker.start
        docker: options.docker
        container: options.name
