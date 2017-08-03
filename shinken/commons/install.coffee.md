
# Shinken Commons Install

    module.exports = header: 'Shinken Install', handler: ->
      {ssl} = @config
      {shinken} = @config.ryba

## Identities

      @system.group header: 'Group', shinken.group
      @system.user header: 'User', shinken.user

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
          target: "#{shinken.user.home}/share"
          uid: shinken.user.name
          gid: shinken.group.name
        @system.mkdir
          target: "#{shinken.user.home}/doc"
          uid: shinken.user.name
          gid: shinken.group.name
        @system.mkdir
          target: "#{shinken.build_dir}"
        @system.mkdir
          target: shinken.log_dir
          uid: shinken.user.name
          gid: shinken.group.name
        @system.execute
          cmd: 'shinken --init'
          unless_exists: "/root/.shinken.ini"

## SSL Layout

      @call
        if: -> shinken.config['use_ssl'] is '1'
        header: 'SSL Layout'
      , ->
        @file.download
          target: shinken.config['ca_cert']
          source: ssl.cacert.source
          local: ssl.cacert.local
        @file.download
          target: shinken.config['server_cert']
          source: ssl.cert.source
          local: ssl.cert.local
        @file.download
          target: shinken.config['server_key']
          source: ssl.key.source
          local: ssl.key.local

## Python Modules

      @call header: 'Python Modules', ->
        # We compute the module list only once because pip list can be very slow
        @system.execute
          cmd: "pip list > #{shinken.build_dir}/.piplist"
          shy: true
        @each shinken.python_modules, (options, callback) ->
          v = options.value
          @call
            header: options.key
            unless_exec: "grep #{options.key} #{shinken.build_dir}/.piplist"
          , ->
            @file.download
              source: v.url
              target: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
              cache_file: "#{v.archive}.#{v.format}"
            @tools.extract
              source: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
            @system.execute
              cmd:"""
              cd #{shinken.build_dir}/#{v.archive}
              python setup.py build
              python setup.py install
              """
            @system.remove target: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
            @system.remove target: "#{shinken.build_dir}/#{v.archive}"
          @then callback
        @system.remove
          target: "#{shinken.build_dir}/.piplist"
          shy: true
