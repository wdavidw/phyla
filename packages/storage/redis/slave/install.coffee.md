
# Install Redis Master

This modules install the redis package and configure it as a master.

    module.exports = header: 'Redis Slave Install', handler: (options) ->
      

## Package
Install Redis from Epel Repositories

      @call header: 'Packages', ->
        @service
          name: 'redis'
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/redis.service'
            source: "#{__dirname}/../resources/redis-systemd.j2"
            local: true
            context:
              config_file: "#{options.slave.conf_dir}/redis.conf"
              user: options.user.name
              group: options.group.name
            mode: 0o0644
            backup: true
          @system.tmpfs
            header: 'Run dir'
            mount: options.slave.pid_dir
            uid: options.user.name
            gid: options.group.name
            perm: '0750'

## IPTables

| Service       | Port  | Proto       | Parameter          |
|---------------|-------|-------------|--------------------|
| Redis Slave   | 6379  | tcp         | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'Iptables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.conf['port'], protocol: 'tcp', state: 'NEW', comment: "Redis Slave" }
        ]


## Layout
        
      @system.mkdir
        header: 'Snpashots dir'
        target: options.slave.conf['dir']
        uid: options.user.name
        gid: options.group.name
        mode: 0o750
      @system.mkdir
        header: 'Log dir'
        target: path.dirname options.slave.conf['logfile']
        uid: options.user.name
        gid: options.group.name
        mode: 0o750


## Configuration
      
      @file.types.redis_conf
        header: 'Server properties'
        target: "#{options.slave.conf_dir}/redis.conf"
        content: options.slave.conf
        backup: true
        eof: true
        mode: 0o0750
        uid: options.user.name
        gid: options.group.name

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'
