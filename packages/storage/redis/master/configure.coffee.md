
# Configure redis

Redis replication adopts a slave-master architecture. This module configure the master
that slave will link to. Redis does only user one master.

    module.exports = (service) ->
      options = service.options

## Identities

The Redis package does create the redis user.

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'redis'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'redis'
      options.user.system ?= true
      options.user.comment ?= 'Redis Database Server'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.groups ?= []
      options.user.gid = options.group.name

## Master Configuration

      # Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false
      options.conf_dir ?= "/etc/redis"
      options.pid_dir ?= '/var/run/redis'
      options.log_dir ?= '/var/log/redis'
      
## Configuration

      
      options.conf ?= {}
      options.conf['port'] ?= '6379'
      options.conf['pidfile'] ?= "#{options.pid_dir}/redis.pid"
      options.conf['daemonize'] ?= 'no'
      options.conf['tcp-backlog'] ?= '511' #somaxconn #tcp_max_syn_backlog
      options.conf['bind'] ?= '0.0.0.0'
      options.conf['timeout'] ?= '0'
      options.conf['loglevel'] ?= 'notice'
      options.conf['logfile'] ?= "#{options.log_dir}/redis.log"
      options.conf['databases'] ?= '16'
      
## Snapshotting
      
      options.conf['save'] ?= '900 1' #save <seconds> <changes>
      options.conf['stop-writes-on-bgsave-error'] ?= 'yes'
      options.conf['rdbcompression'] ?= 'yes'
      options.conf['rdbchecksum'] ?= 'yes'
      options.conf['dbfilename'] ?= 'dump.rdb'
      options.conf['dir'] ?= "#{options.user.home}/snapshots"
      options.conf['appendonly'] ?= 'yes'

## Replication
Options by default configured from [Redis Official][redis-replication] documentation
      
      options.conf['slave-serve-stale-data'] ?= 'yes'
      options.conf['min-slaves-to-write'] ?= '1'
      options.conf['min-slaves-max-lag'] ?= '30'

## Security
Add password authentication
      
      options.master_password ?= 'redis123'
      throw Error 'Missing Redis master password' unless options.master_password?
      options.conf['requirepass'] ?= options.master_password

## Wait

      options.wait = 
        host: service.node.fqdn
        port: options.conf.port

## Dependencies

    quote = require 'regexp-quote'

[redis-replication]:https://redis.io/topics/replication
[redis-cluster]: https://redis.io/topics/cluster-tutorial
