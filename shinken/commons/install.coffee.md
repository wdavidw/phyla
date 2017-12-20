
# Shinken Commons Install

    module.exports = header: 'Shinken Install', handler: (options) ->

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Packages

      @call header: 'Packages', ->
        @service name: 'python'
        @service name: 'python-pip'
        @service name: 'libcurl-devel'
        @service name: 'python-pycurl'
        @service name: 'python-devel'
        @service name: 'gcc'
        @service name: 'libffi-devel'
        @service name: 'shinken'

## Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: '/etc/shinken/packs'
        @system.mkdir
          target: "#{options.user.home}/share"
          uid: options.user.name
          gid: options.group.name
        @system.mkdir
          target: "#{options.user.home}/doc"
          uid: options.user.name
          gid: options.group.name
        @system.mkdir
          target: "#{options.build_dir}"
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
        @system.execute
          cmd: 'shinken --init'
          unless_exists: "/root/.options.ini"

## SSL Layout

      @call
        if: -> options.ssl.enabled
        header: 'SSL Layout'
      , ->
        @file.download
          target: options.config['ca_cert']
          source: options.ssl.cacert.source
          local: options.ssl.cacert.local
        @file.download
          target: options.config['server_cert']
          source: options.ssl.cert.source
          local: options.ssl.cert.local
        @file.download
          target: options.config['server_key']
          source: options.ssl.key.source
          local: options.ssl.key.local

## Python Modules

      @call header: 'Python Modules', ->
        # We compute the module list only once because pip list can be very slow
        @system.execute
          cmd: "pip list > #{options.build_dir}/.piplist"
          shy: true
        @each options.python_modules, (opts, callback) ->
          v = opts.value
          @call
            header: opts.key
            unless_exec: "grep #{opts.key} #{options.build_dir}/.piplist"
          , ->
            @file.download
              source: v.url
              target: "#{options.build_dir}/#{v.archive}.#{v.format}"
              cache_file: "#{v.archive}.#{v.format}"
            @tools.extract
              source: "#{options.build_dir}/#{v.archive}.#{v.format}"
            @system.execute
              cmd:"""
              cd #{options.build_dir}/#{v.archive}
              python setup.py build
              python setup.py install
              """
            @system.remove target: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
            @system.remove target: "#{shinken.build_dir}/#{v.archive}"
          @next callback
        @system.remove
          target: "#{options.build_dir}/.piplist"
          shy: true
