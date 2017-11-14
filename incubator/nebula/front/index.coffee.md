
# OpenNebula Front

OpenNebula is an open-source management platform to build IaaS private, public and hybrid clouds.

    module.exports =
      deps:
        nebula_base: module: 'ryba/incubator/nebula/base', local: true, auto: true, implicit: true
        nebula_node: module: 'ryba/incubator/nebula/node'
      configure:
        'ryba/incubator/nebula/front/configure'
      commands:
        'check':
          'ryba/incubator/nebula/front/check'
        'prepare':
          'ryba/incubator/nebula/front/prepare'
        'install':
          'ryba/incubator/nebula/front/install'
          'ryba/incubator/nebula/front/start'
        'start':
          'ryba/incubator/nebula/front/start'
        'stop':
          'ryba/incubator/nebula/front/stop'
