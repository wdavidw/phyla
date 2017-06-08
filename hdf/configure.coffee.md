
# HDF Configure

    module.exports = ->
      @config.ryba.hdf ?= {}
      options = @config.ryba.hdf
      options.repo ?= 'http://public-repo-1.hortonworks.com/HDF/centos7/2.x/updates/2.1.2.0/hdf.repo'
      options.target ?= 'hdf.repo'
      options.target = path.posix.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'hdf*'

## Dependencies

    path = require('path').posix
