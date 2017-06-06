
# HDP Configure

    module.exports = ->
      @config.ryba.hdp ?= {}
      options = @config.ryba.hdp
      options.repo ?= 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.5.3.0/hdp.repo'
      options.target ?= 'hdp.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'hdp*'

## Dependencies

    path = require 'path'.posix
