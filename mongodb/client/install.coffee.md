
# MongoDB Client Install

    module.exports = header: 'MongoDB Client Packages', handler: ->
      @service name: 'mongodb-org-shell'
      @service name: 'mongodb-org-tools'
