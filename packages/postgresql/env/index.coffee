shell = require 'shell'

shell
  name: 'lxdcluster'
  description: 'Manage LXD clusters'
  options:
    'clusterconf': shortcut: 'c', default: './config'
    'logdir': shortcut: 'l', default: '.log'
    'debug': shortcut: 'd', default: false
  commands:
    'start':
      description: 'Create and start the LXD cluster (networks and containers)'
      handler: require './start'
    'stop':
      description: 'Stop the LXD cluster'
      options:
        'wait': shortcut: 'w', type: 'boolean'
      handler: require './stop'
    'delete':
      description: 'Delete the LXD cluster (networks and containers)'
      options:
        'force': shortcut: 'f', type: 'boolean'
      handler: require './delete'
.route()
