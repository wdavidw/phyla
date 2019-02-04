
#  Hue Prepare

Follows Cloudera [build-instruction][cloudera-hue] for Hue 3.7 and later version.
An internet Connection is needed to be able to download.
Becareful when used with docker-machine nikita might exit before finishing
the execution. you can resume build by executing again prepare

First container
```
cd /tmp/@rybajs/metal/hue-build/
eval "$(docker-machine env dev)" && docker build -t "@rybajs/metal/hue-build" .
```

Second container
```
cd /tmp/@rybajs/metal/hue-build/
eval "$(docker-machine env dev)" && docker build -t "@rybajs/metal/hue-build" .
```

Builds Hue from source


    module.exports = header: 'Hue Docker Prepare', ssh: false, handler: (options) ->

# Hue compiling build from Dockerfile

Builds Hue in two steps:
1 - the first step creates a docker container to build hue from source with all the tools needed
2 - the second step builds a production ready @rybajs/metal/hue image by setting:
  * the needed yum packages
  * user and group layout
It's the install middleware which takes care about mounting the differents volumes
for hue to be able to communicate with the hadoop cluster in secure mode.

# Hue Build dockerfile execution

      @call header: 'Build Prepare', ->
        @system.mkdir
          target: "#{options.cache_dir}/huedocker"
        @system.mkdir
          target: "#{path.resolve options.cache_dir, options.build.directory}/"
        @system.copy
          unless: options.build.source.indexOf('.git') > 0
          source: options.build.source
          target: "#{path.resolve options.cache_dir, options.build.directory}/hue"
        @tools.git
          if: options.build.source.indexOf('.git') > 0
          source: options.build.source
          target: "#{path.resolve options.cache_dir, options.build.directory}/hue"
          revision: options.build.revision
        @file.render
          source: options.build.dockerfile
          target: "#{path.resolve options.cache_dir, options.build.directory}/Dockerfile"
          context:
            source: 'hue'
            user: options.user.name
            uid: options.user.uid
            gid: options.user.uid
        @docker.build
          image: "#{options.build.name}:#{options.build.version}"
          file: "#{path.resolve options.cache_dir, options.build.directory}/Dockerfile"
        @docker.service
          image: "#{options.build.name}:#{options.build.version}"
          name: 'ryba_hue_extractor'
          entrypoint: '/bin/bash'
        @system.mkdir
          target: "#{path.resolve options.cache_dir, options.prod.directory}"
        @docker.cp
          container: 'ryba_hue_extractor'
          source: 'ryba_hue_extractor:/hue-build.tar.gz'
          target: path.resolve options.cache_dir, options.prod.directory
        @docker.rm
          container: 'ryba_hue_extractor'
          force: true

# Hue Production dockerfile execution

This production container running as hue service

      @call header: 'Production Container', ->
        @file.render
          source: options.prod.dockerfile
          target: "#{path.resolve options.cache_dir, options.prod.directory}/Dockerfile"
          context:
            user: options.user.name
            uid: options.user.uid
            gid: options.group.gid
        @file.render
          source: "#{__dirname}/resources/hue_init.sh"
          target: "#{options.prod.directory}/hue_init.sh"
          context:
            pid_file: options.pid_file
            user: options.user.name
        # docker build -t "@rybajs/metal/hue-build:3.9" .
        @docker.build
          image: "#{options.image}:#{options.version}"
          file: "#{options.prod.directory}/Dockerfile"
        , (err, _, checksum) ->
          throw err if err
          @file
            content: "#{checksum}"
            target: "#{options.prod.directory}/checksum"
        @docker.save
          image: "#{options.image}:#{options.version}"
          output: "#{options.prod.directory}/#{options.prod.tar}"

## Dependencies

    path = require 'path'

## Instructions

[cloudera-hue]:(https://github.com/cloudera/hue#development-prerequisites)
