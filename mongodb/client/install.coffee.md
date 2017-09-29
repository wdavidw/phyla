
# MongoDB Client Install

    module.exports = header: 'MongoDB Client Packages', handler: (options) ->
      @service name: 'mongodb-org-shell'
      @service name: 'mongodb-org-tools'
