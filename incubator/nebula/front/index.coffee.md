
# OpenNebula Front

OpenNebula is an open-source management platform to build IaaS private, public and hybrid clouds.

    module.exports =
      use:
        nebula_base: module: 'ryba/incubator/nebula/base', local: true, auto: true, implicit: true
        nebula_node: module: 'ryba/incubator/nebula/node'
      configure: 'ryba/incubator/nebula/front/configure'
      commands:
        'check': ->
          options = @config.nebula.front
          @call 'ryba/incubator/nebula/front/check', options
        'prepare': ->
          options = @config.nebula.front
          @call 'ryba/incubator/nebula/front/prepare', options
        'install': ->
          options = @config.nebula.front
          @call 'ryba/incubator/nebula/front/install', options
          @call 'ryba/incubator/nebula/front/start', options
        'start': ->
          options = @config.nebula.front
          @call 'ryba/incubator/nebula/front/start', options
        'stop': ->
          options = @config.nebula.front
          @call 'ryba/incubator/nebula/front/stop', options
