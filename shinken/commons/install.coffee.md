
# Shinken Install

    module.exports = header: 'Shinken Install', handler: ->
      {shinken} = @config.ryba

## Identities

      @system.group header: 'Group', shinken.group
      @system.user header: 'User', shinken.user

## Commons Packages

      @call header: 'Commons Packages', ->
        @service name: 'python'
        @service name: 'python-pip'
        @service name: 'libcurl-devel'
        @service name: 'python-pycurl'
        @service name: 'python-devel'
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
          unless_exists: "#{shinken.user.home}/.shinken.ini"

## Python Modules

      @call header: 'Python Modules', ->
        for k, v of shinken.python_modules
          @call header: k, unless_exec: "pip list | grep #{k}", ->
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
