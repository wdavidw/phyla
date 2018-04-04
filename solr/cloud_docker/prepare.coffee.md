
# Solr Cloud Docker Prepare

Build container and save it.

    module.exports =
      header: 'Solr Cloud Docker Prepare'
      ssh: false
      handler: (options) ->
        @system.mkdir
          target: options.build.dir
        @system.mkdir
          target: "#{options.build.dir}/build"
        @file.render
          source: "#{__dirname}/../resources/cloud_docker/docker_entrypoint.sh.j2"
          target: "#{options.build.dir}/build/docker_entrypoint.sh"
          context: options
        @file.render
          source: "#{__dirname}/../resources/cloud_docker/Dockerfile.j2"
          target: "#{options.build.dir}/build/Dockerfile"
          context: options
        @file.render
          source: "#{__dirname}/../resources/cloud_docker/java.sh.j2"
          target: "#{options.build.dir}/build/java.sh"
          context: options
        @docker.build
          image: "#{options.build.image}:#{options.version}"
          file: "#{options.build.dir}/build/Dockerfile"
        @docker.save
          image: "#{options.build.image}:#{options.version }"
          output: "#{options.build.dir}/#{options.build.tar}"
