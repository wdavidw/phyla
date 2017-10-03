
# Open Nebula Front Install

Install Nebula front end on the specified hosts.
http://docs.opennebula.org/5.2/deployment/opennebula_installation/frontend_installation.html

    module.exports = header: 'Nebula Front Install', handler: (options) ->

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

        @call header: 'Packages', ->
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

## Set private and public key for oneadmin

      # @call if: options.private_key_path, (_, callback) ->
      #   ssh = if options.local then null else options.ssh
      #   console.log !!ssh, options.private_key_path
      #   fs.readFile ssh, options.private_key_path, 'ascii', (err, data) ->
      #     options.private_key = data unless err
      #     callback err
      # @call if: options.public_key_path, (_, callback) ->
      #   ssh = if options.local then null else options.ssh
      #   fs.readFile ssh, options.public_key_path, 'ascii', (err, data) ->
      #     options.public_key = data unless err
      #     callback err
      @call header: 'Set keys', ->
        @file
          header: "private"
          target: "/var/lib/one/.ssh/id_rsa"
          mode: 0o0600
          eof: true
        , options.private_key
        @file
          header: "public"
          target: "/var/lib/one/.ssh/id_rsa.pub"
          mode: 0o0600
          eof: true
        , options.public_key

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
