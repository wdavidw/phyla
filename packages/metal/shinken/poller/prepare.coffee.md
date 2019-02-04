
# Shinken Poller Prepare

Download Modules
Prepare shinken-poller-executor docker image

    module.exports = header: 'Shinken Poller Prepare', handler: (options) ->
      return unless options.prepare

## Modules

      @call header: 'Modules', ->
        installmod = (name, mod) =>
          @file.cache
            source: mod.source
            cache_file: "#{mod.archive}.#{mod.format}"
          for subname, submod of mod.modules then installmod subname, submod
        for name, mod of options.modules then installmod name, mod

## Python Modules

      @call header: 'Python Modules', ->
        for _, mod of options.modules then for k,v of mod.python_modules
          @file.cache
              source: v.url
              cache_file: "#{v.archive}.#{v.format}"

## Build Container

      @file.render
        header: 'Render Dockerfile'
        target: "#{options.cache_dir or '.'}/build/Dockerfile"
        source: "#{__dirname}/resources/Dockerfile.j2"
        local: true
        context: options
      @file
        header: 'Write Java Profile'
        target: "#{options.cache_dir or '.'}/build/java.sh"
        content: """
        export JAVA_HOME=/usr/java/default
        export PATH=/usr/java/default/bin:$PATH
        """
      @file
        header: 'Write RSA Private Key'
        target: "#{options.cache_dir or '.'}/build/id_rsa"
        content: options.private_key
      @file
        header: 'Write RSA Public Key'
        target: "#{options.cache_dir or '.'}/build/id_rsa.pub"
        content: options.public_key
      @docker.build
        header: 'Build Container'
        image: '@rybajs/metal/shinken-poller-executor'
        file: "#{options.cache_dir or '.'}/build/Dockerfile"
        cwd: options.build_dir

## Save image

      @docker.save
        header: 'Save Container'
        image: '@rybajs/metal/shinken-poller-executor'
        target: "#{options.cache_dir or '.'}/shinken-poller-executor.tar"
