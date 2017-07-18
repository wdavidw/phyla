
# Shinken Poller Prepare

Download Modules
Prepare shinken-poller-executor docker image

    module.exports =
      header: 'Shinken Poller Prepare'
      if: -> @contexts('ryba/shinken/poller')[0].config.host is @config.host
      handler: ->
        {poller} = @config.ryba.shinken

## Modules

        @call header: 'Modules', ->
          installmod = (name, mod) =>
            @file.cache
              source: mod.source
              cache_file: "#{mod.archive}.#{mod.format}"
            for subname, submod of mod.modules then installmod subname, submod
          for name, mod of poller.modules then installmod name, mod

## Python Modules

        @call header: 'Python Modules', ->
          for _, mod of poller.modules then for k,v of mod.python_modules
            @file.cache
                source: v.url
                cache_file: "#{v.archive}.#{v.format}"

## Build Container

        @file.render
          header: 'Render Dockerfile'
          target: "#{@config.nikita.cache_dir or '.'}/build/Dockerfile"
          source: "#{__dirname}/resources/Dockerfile.j2"
          local: true
          context: @config.ryba
        @file
          header: 'Write Java Profile'
          target: "#{@config.nikita.cache_dir or '.'}/build/java.sh"
          content: """
          export JAVA_HOME=/usr/java/default
          export PATH=/usr/java/default/bin:$PATH
          """
        @file
          header: 'Write RSA Private Key'
          target: "#{@config.nikita.cache_dir or '.'}/build/id_rsa"
          content: @config.ssh.private_key
        @file
          header: 'Write RSA Public Key'
          target: "#{@config.nikita.cache_dir or '.'}/build/id_rsa.pub"
          content: @config.ssh.public_key
        @docker.build
          header: 'Build Container'
          image: 'ryba/shinken-poller-executor'
          file: "#{@config.nikita.cache_dir or '.'}/build/Dockerfile"
          cwd: poller.executor.build_dir

## Save image

        @docker.save
          header: 'Save Container'
          image: 'ryba/shinken-poller-executor'
          target: "#{@config.nikita.cache_dir or '.'}/shinken-poller-executor.tar"
