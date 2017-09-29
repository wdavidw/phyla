
# Zookeeper Server Install

    module.exports = header: 'ZooKeeper Server Install', handler: (options) ->

## Register

      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Wait

      @call once: true, 'masson/core/krb5_client/wait', options.wait_krb5_client

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

      @system.group header: 'Group', options.group
      @system.group header: 'Spnego Group', options.hadoop_group
      @system.user header: 'User', options.user

## IPTables

| Service    | Port | Proto  | Parameter             |
|------------|------|--------|-----------------------|
| zookeeper  | 2181 | tcp    | zookeeper.port        |
| zookeeper  | 2888 | tcp    | zookeeper.peer_port   |
| zookeeper  | 3888 | tcp    | zookeeper.leader_port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      rules = [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.peer_port, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Peer" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.leader_port, protocol: 'tcp', state: 'NEW', comment: "Zookeeper Leader" }
      ]
      if options.env["JMXPORT"]?
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: parseInt(options.env["JMXPORT"],10), protocol: 'tcp', state: 'NEW', comment: "Zookeeper JMX" }

We open the client port if:
- the node is an observer
- the node is participant but there is no other observer on the cluster

      if options.config['peerType'] is 'observer' or @contexts('ryba/zookeeper/server').filter( (ctx) -> options.config['peerType'] is 'observer' ).length is 0
        rules.push { chain: 'INPUT', jump: 'ACCEPT', dport: options.config['clientPort'], protocol: 'tcp', state: 'NEW', comment: "Zookeeper Client" }
      @tools.iptables
        header: 'IPTables'
        rules: rules
        if: options.iptables

## Packages

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

      @call header: 'Packages', ->
        @service
          name: 'nc' # Used by check
        @service
          name: 'zookeeper-server'
        @hdp_select
          name: 'zookeeper-server'
        @hdp_select
          name: 'zookeeper-client'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          source: "#{__dirname}/resources/zookeeper"
          local: true
          target: '/etc/init.d/zookeeper-server'
        #TODO: Move pid creation dir to systemd startup scripts
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            source: "#{__dirname}/resources/zookeeper-systemd.j2"
            local: true
            context: @config.ryba
            target: '/usr/lib/systemd/system/zookeeper-server.service'
            mode: 0o0644
          @system.tmpfs
            mount: options.pid_dir
            uid: options.user.name
            gid: options.group.name
            perm: '0750'

## Kerberos

      @call header: 'Kerberos', ->
        @krb5.addprinc options.krb5.admin,
          principal: options.krb5.principal
          randkey: true
          keytab: options.krb5.keytab
          uid: options.user.name
          gid: options.hadoop_group.name
        @file.jaas
          target: '/etc/zookeeper/conf/zookeeper-server.jaas'
          content: Server:
            principal: options.krb5.principal
            keyTab: options.krb5.keytab
          uid: options.user.name
          gid: options.hadoop_group.name
        @file.jaas
          target: "#{options.conf_dir}/zookeeper-client.jaas"
          content: Client:
            useTicketCache: true
          mode: 0o0644

## Layout

Create the data, pid and log directories with the correct permissions and
ownerships.

      @call header: 'Layout', ->
        @system.mkdir
          target: options.config['dataDir']
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o755
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755

## Super User

Enables a ZooKeeper ensemble administrator to access the znode hierarchy as a
"super" user.

This functionnality is disactivated by default. Enable it by setting the
configuration property "ryba.zookeeper.superuser.password". The digest auth
passes the authdata in plaintext to the server. Use this authentication method
only on localhost (not over the network) or over an encrypted connection.

Run "zkCli.sh" and enter `addauth digest super:EjV93vqJeB3wHqrx`

      @system.execute
        header: 'Generate Super User'
        if: options.superuser.password
        cmd: """
        ZK_HOME=/usr/hdp/current/zookeeper-client/
        java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider super:#{options.superuser.password}
        """
      , (err, generated, stdout) ->
        throw err if err
        return unless generated # probably because password not set
        digest = match[1] if match = /\->(.*)/.exec(stdout)
        throw Error "Failed to get digest: bad output" unless digest
        options.env['SERVER_JVMFLAGS'] = "-Dzookeeper.DigestAuthenticationProvider.superDigest=#{digest} #{options.env['SERVER_JVMFLAGS']}"

## Environment

Note, environment is enriched at runtime if a super user is generated
(see above).

      @file
        header: 'Environment'
        target: "#{options.conf_dir}/zookeeper-env.sh"
        content: ("export #{k}=\"#{v}\"" for k, v of options.env).join '\n'
        backup: true
        eof: true
        mode: 0o750
        uid: options.user.name
        gid: options.group.name

## Configure

Update the file "zoo.cfg" with the properties defined by the
"ryba.zookeeper.config" configuration.

      @file.properties
        header: 'Configure'
        target: "#{options.conf_dir}/zoo.cfg"
        content: options.config
        sort: true
        backup: true

## Log4J

Write the ZooKeeper logging configuration file.

      @file.properties
        header: 'Log4J'
        target: "#{options.conf_dir}/log4j.properties"
        content: options.log4j.config
        backup: true

## Schedule Purge Transaction Logs

A ZooKeeper server will not remove old snapshots and log files when using the
default configuration (see autopurge below), this is the responsibility of the
operator.

The PurgeTxnLog utility implements a simple retention policy that administrators
can use. Its expected arguments are "dataLogDir [snapDir] -n count".

Note, Automatic purging of the snapshots and corresponding transaction logs was
introduced in version 3.4.0 and can be enabled via the following configuration
parameters autopurge.snapRetainCount and autopurge.purgeInterval.

```
/usr/bin/java \
  -cp /usr/hdp/current/zookeeper-server/zookeeper.jar:/usr/hdp/current/zookeeper-server/lib/*:/usr/hdp/current/zookeeper-server/conf \
  org.apache.zookeeper.server.PurgeTxnLog  /var/zookeeper/data/ -n 3
```

      @cron.add
        header: 'Schedule Purge'
        if: options.purge
        cmd: """
        /usr/bin/java -cp /usr/hdp/current/zookeeper-server/zookeeper.jar:/usr/hdp/current/zookeeper-server/lib/*:/usr/hdp/current/zookeeper-server/conf \
          org.apache.zookeeper.server.PurgeTxnLog \
          #{options.config.dataLogDir or ''} #{options.config.dataDir} -n #{options.retention}
        """
        when: options.purge
        user: options.user.name

## Write myid

myid is a unique id that must be generated for each node of the zookeeper cluster

      @file
        header: 'Write id'
        content: options.id
        target: "#{options.config['dataDir']}/myid"
        uid: options.user.name
        gid: options.hadoop_group.name

## Resources

* [ZooKeeper Resilience](http://blog.cloudera.com/blog/2014/03/zookeeper-resilience-at-pinterest/)
* [HDP Install Instructions]: http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.1-latest/bk_installing_manually_book/content/rpm-zookeeper-1.html
