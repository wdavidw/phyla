
# OpenNebula Front Install

Install Nebula front end on the specified hosts.
http://docs.opennebula.org/5.2/deployment/opennebula_installation/frontend_installation.html

    module.exports = header: 'OpenNebula Front Install', handler: (options) ->

## Install

      @call header: 'Packages', ->
        @service
          header: 'opennebula-ruby'
          name: 'opennebula-ruby'
        @service
          header: 'opennebula-gate'
          name: 'opennebula-gate'
        @service
          header: 'opennebula-flow'
          name: 'opennebula-flow'
        @service
          header: 'opennebula server'
          name: 'opennebula-server'
          srv_name: 'opennebula'
          startup: true
        @service
          header: 'opennebula sunstone'
          name: 'opennebula-sunstone'
          startup: true

## Ruby Runtime installation

        @service
          header: 'g++'
          name: 'gcc-c++'
        @service
          header: 'gcc'
          name: 'gcc'
        @service
          header: 'curl-devel'
          name: 'curl-devel'
        @service
          header: 'mysql-devell'
          name: 'mysql-devel'
        @service
          header: 'openssl-devel'
          name: 'openssl-devel'
        @service
          header: 'ruby-devel'
          name: 'ruby-devel'
        @service
          header: 'make'
          name: 'make'
        @service
          header: 'rubygems'
          name: 'rubygems'
        @call header: 'Gems install', ->
          @tools.rubygems.install
            if: options.cache_dir
            source: path.resolve options.cache_dir, 'vendor', 'cache', "*.gem"
          @tools.rubygems.install
            unless: options.cache_dir
            gems:
              'rack': '< 2.0.0'
              'sinatra': '< 2.0.0'
              'thin': null
              'memcache-client': null
              'zendesk_api': '< 1.14.0'
              'builder': null
## Mysql

TODO
http://docs.opennebula.org/5.2/deployment/opennebula_installation/mysql_setup.html#mysql-setup

## Set password

      @call header: 'Password', ->
        @file
          content: "oneadmin:#{options.password}"
          target: "/var/lib/one/.one/one_auth"
          eof: true

## Add nodes key to known_hosts

      @call header: 'Add node host to known_hosts', ->
        @system.execute
          if: options.nebula_node_hosts && options.nebula_node_hosts.length > 0
          cmd: "su oneadmin -c 'ssh-keyscan #{options.nebula_node_hosts.join(' ')} > /var/lib/one/.ssh/known_hosts'"
        @system.execute
          cmd: "su oneadmin -c 'ssh-keyscan $HOSTNAME >> /var/lib/one/.ssh/known_hosts'"
        @system.chmod
          target: "/var/lib/one/.ssh/known_hosts"
          mode: "0600"
        @system.chown
          target: "/var/lib/one/.ssh/known_hosts"
          uid: "oneadmin"
          gid: "oneadmin"
          
## Start services

      @call header: 'Starting OpenNebula Front-End', ->
        @service.start
          name: 'opennebula'
        @service.start
          name: 'opennebula-sunstone'

## Add Nodes

      @call header: 'Add node host to opennebula', ->
        for node_host in options.nebula_node_hosts
          @system.execute
            cmd: "su oneadmin -c 'onehost create #{node_host} -i kvm -v kvm'"
            code_skipped: 255 

## Dependencies

    path = require 'path'
    fs = require 'ssh2-fs'
