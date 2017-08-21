
# ZooKeeper Client Configure

*   `zookeeper.user` (object|string)   
    The Unix Zookeeper login name or a user object (see Nikita User documentation).   
*   `zookeeper.env` (object)   
    Map of variables present in "zookeeper-env.sh" and used to initialize the server.   
*   `zookeeper.config` (object)   
    Map of variables present in "zoo.cfg" and used to configure the server.   

Example :

```json
{ "ryba": {
    "zookeeper" : {
      "user": {
        "name": "zookeeper", "system": true, "gid": "hadoop",
        "comment": "Zookeeper User", "home": "/var/lib/zookeeper"
      }
    }
} }
```

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/zookeeper/server', ['ryba', 'zookeeper'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        java: key: ['java']
        hdp: key: ['hdp']
        krb5_client: key: ['krb5_client']
        zookeeper_server: key: ['ryba', 'zookeeper']
      @config.ryba ?= {}
      options = @config.ryba.zookeeper = service.options

## Environment

      # Layout
      options.conf_dir ?= '/etc/zookeeper/conf'
      options.log_dir ?= '/var/log/zookeeper'
      options.pid_dir ?= '/var/run/zookeeper'
      options.port ?= 2181
      options.conf_dir ?= '/etc/zookeeper/conf'
      # Misc
      options.clean_logs ?= false
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'

## Identities

      # Groups
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'zookeeper'
      options.group.system ?= true
      # Hadoop Group is also defined in ryba/hadoop/core
      options.hadoop_group = name: options.hadoop_group if typeof options.hadoop_group is 'string'
      options.hadoop_group ?= {}
      options.hadoop_group.name ?= 'hadoop'
      options.hadoop_group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'zookeeper'
      options.user.system ?= true
      options.user.gid ?= options.group.name
      options.user.groups ?= 'hadoop'
      options.user.comment ?= 'Zookeeper User'
      options.user.home ?= '/var/lib/zookeeper'

## Configuration

      options.env ?= {}
      options.env['ZOOKEEPER_HOME'] ?= "/usr/hdp/current/zookeeper-client"
      options.env['ZOO_AUTH_TO_LOCAL'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
      options.env['ZOO_LOG_DIR'] ?= "#{options.log_dir}"
      options.env['ZOOPIDFILE'] ?= "#{options.pid_dir}/zookeeper_server.pid"
      options.env['SERVER_JVMFLAGS'] ?= "-Xmx1024m -Djava.security.auth.login.config=#{options.conf_dir}/zookeeper-server.jaas"
      options.env['CLIENT_JVMFLAGS'] ?= "-Djava.security.auth.login.config=#{options.conf_dir}/zookeeper-client.jaas"
      options.env['JAVA'] ?= '$JAVA_HOME/bin/java'
      options.env['JAVA_HOME'] ?= "#{service.use.java.options.java_home}"
      options.env['CLASSPATH'] ?= '$CLASSPATH:/usr/share/zookeeper/*'
      options.env['ZOO_LOG4J_PROP'] ?= 'INFO,ROLLINGFILE' #was 'INFO,CONSOLE, ROLLINGFILE'
      if options.env['SERVER_JVMFLAGS'].indexOf('-Dzookeeper.security.auth_to_local') is -1
        options.env['SERVER_JVMFLAGS'] = "#{options.env['SERVER_JVMFLAGS']} -Dzookeeper.security.auth_to_local=$ZOO_AUTH_TO_LOCAL"
      if options.env['JMXPORT']? and options.env['SERVER_JVMFLAGS'].indexOf('-Dcom.sun.management.jmxremote.rmi.port') is -1
        options.env['SERVER_JVMFLAGS'] = "#{options.env['SERVER_JVMFLAGS']} -Dcom.sun.management.jmxremote.rmi.port=$JMXPORT"
      # Internal
      options.id ?= service.use.zookeeper_server.map( (srv) -> srv.node.fqdn ).indexOf(service.node.fqdn)+1
      options.peer_port ?= 2888
      options.leader_port ?= 3888
      options.retention ?= 3 # Used to clean data dir
      options.purge ?= '@weekly'
      options.purge = '@weekly' if options.purge is true
      # Configuration
      options.config ?= {}
      options.config['maxClientCnxns'] ?= '200'
      # The number of milliseconds of each tick
      options.config['tickTime'] ?= '2000'
      # The number of ticks that the initial synchronization phase can take
      options.config['initLimit'] ?= '10'
      options.config['tickTime'] ?= '2000'
      # The number of ticks that can pass between
      # sending a request and getting an acknowledgement
      options.config['syncLimit'] ?= '5'
      # The directory where the snapshot is stored.
      # Recommandation is 1 dedicated SSD drive.
      options.config['dataDir'] ?= '/var/zookeeper/data/'
      # the port at which the clients will connect
      options.config['clientPort'] ?= "#{options.port}"
      # If zookeeper node is participant (to election) or only observer
      # Adding new observer nodes allow horizontal scaling without slowing write
      options.config['peerType'] ?= 'participant'
      connect_string = "#{@config.host}:#{options.peer_port}:#{options.leader_port}"
      connect_string += ":observer" if options.config['peerType'] is 'observer'
      for srv, i in service.use.zookeeper_server
        srv.options.config ?= {}
        if srv.options.config["server.#{options.id}"]? and srv.options.config["server.#{options.id}"] isnt connect_string
          throw Error "Zk Server id '#{options.id}' is already registered on #{srv.node.fqdn}"
        srv.options.config["server.#{options.id}"] ?= connect_string
      
      # SASL
      options.config['authProvider.1'] ?= 'org.apache.zookeeper.server.auth.SASLAuthenticationProvider'
      options.config['jaasLoginRenew'] ?= '3600000'
      options.config['kerberos.removeHostFromPrincipal'] ?= 'true'
      options.config['kerberos.removeRealmFromPrincipal'] ?= 'true'
      #http://zookeeper.apache.org/doc/trunk/zookeeperAdmin.html#sc_advancedConfiguration
      options.config['autopurge.snapRetainCount'] ?= '5'
      options.config['autopurge.purgeInterval'] ?= 4
      # Superuser
      options.superuser ?= {}
      # zookeeper.superuser.password ?= 'ryba123'

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      options.krb5.principal ?= "zookeeper/#{service.node.fqdn}@#{options.krb5.realm}"
      options.krb5.keytab ?= '/etc/security/keytabs/zookeeper.service.keytab'
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= @config.krb5_client.admin[options.krb5.realm]

## Log4J

      options.log4j ?= {}
      options.log4j[k] ?= v for k, v of @config.log4j
      if options.log4j.remote_host? and options.log4j.remote_port? and options.env['ZOO_LOG4J_PROP'].indexOf('SOCKET') is -1
        options.env['ZOO_LOG4J_PROP'] = "#{options.env['ZOO_LOG4J_PROP']},SOCKET"
      if options.log4j.server_port? and options.env['ZOO_LOG4J_PROP'].indexOf('SOCKETHUB') is -1
        options.env['ZOO_LOG4J_PROP'] = "#{options.env['ZOO_LOG4J_PROP']},SOCKETHUB"
      options.log4j.config ?= {}
      options.log4j.config['log4j.rootLogger'] ?= options.env['ZOO_LOG4J_PROP']
      options.log4j.config['log4j.appender.CONSOLE'] ?= 'org.apache.log4j.ConsoleAppender'
      options.log4j.config['log4j.appender.CONSOLE.Threshold'] ?= 'INFO'
      options.log4j.config['log4j.appender.CONSOLE.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j.config['log4j.appender.CONSOLE.layout.ConversionPattern'] ?= '%d{ISO8601} - %-5p [%t:%C{1}@%L] - %m%n'
      options.log4j.config['log4j.appender.ROLLINGFILE'] ?= 'org.apache.log4j.RollingFileAppender'
      options.log4j.config['log4j.appender.ROLLINGFILE.Threshold'] ?= 'DEBUG'
      options.log4j.config['log4j.appender.ROLLINGFILE.File'] ?= "#{options.log_dir}/zookeeper.log"
      options.log4j.config['log4j.appender.ROLLINGFILE.MaxFileSize'] ?= '10MB'
      options.log4j.config['log4j.appender.ROLLINGFILE.MaxBackupIndex'] ?= '10'
      options.log4j.config['log4j.appender.ROLLINGFILE.layout'] ?= 'org.apache.log4j.PatternLayout'
      options.log4j.config['log4j.appender.ROLLINGFILE.layout.ConversionPattern'] ?= '%d{ISO8601} - %-5p [%t:%C{1}@%L] - %m%n'
      options.log4j.config['log4j.appender.TRACEFILE'] ?= 'org.apache.log4j.FileAppender'
      options.log4j.config['log4j.appender.TRACEFILE.Threshold'] ?= 'TRACE'
      options.log4j.config['log4j.appender.TRACEFILE.File'] ?= "#{options.log_dir}/zookeeper_trace.log"
      options.log4j.config['log4j.appender.TRACEFILE.layout'] = 'org.apache.log4j.PatternLayout'
      options.log4j.config['log4j.appender.TRACEFILE.layout.ConversionPattern'] ?= '%d{ISO8601} - %-5p [%t:%C{1}@%L][%x] - %m%n'
      if options.log4j.server_port
        options.log4j.config['log4j.appender.SOCKETHUB'] ?= 'org.apache.log4j.net.SocketHubAppender'
        options.log4j.config['log4j.appender.SOCKETHUB.Application'] ?= 'zookeeper'
        options.log4j.config['log4j.appender.SOCKETHUB.Port'] ?= options.log4j.server_port
        options.log4j.config['log4j.appender.SOCKETHUB.BufferSize'] ?= '100'
      if options.log4j.remote_host and options.log4j.remote_port
        options.log4j.config['log4j.appender.SOCKET'] ?= 'org.apache.log4j.net.SocketAppender'
        options.log4j.config['log4j.appender.SOCKET.Application'] ?= 'zookeeper'
        options.log4j.config['log4j.appender.SOCKET.RemoteHost'] ?= options.log4j.remote_host
        options.log4j.config['log4j.appender.SOCKET.Port'] ?= options.log4j.remote_port
        options.log4j.config['log4j.appender.SOCKET.ReconnectionDelay'] ?= '10000'

## Wait

      options.wait = {}
      options.wait_krb5_client = service.use.krb5_client.options.wait

## Dependencies

    migration = require 'masson/lib/migration'
