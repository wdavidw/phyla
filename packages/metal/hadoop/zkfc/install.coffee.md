
# Hadoop ZKFC Install

    module.exports = header: 'HDFS ZKFC Install', handler: ({options}) ->

## Register

      @registry.register 'hconfigure', '@rybajs/metal/lib/hconfigure'
      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'
      @registry.register ['file', 'jaas'], '@rybajs/metal/lib/file_jaas'

## IPTables

| Service   | Port | Proto  | Parameter                  |
|-----------|------|--------|----------------------------|
| namenode  | 8019  | tcp   | dfs.ha.zkfc.port           |

      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hdfs_site['dfs.ha.zkfc.port'], protocol: 'tcp', state: 'NEW', comment: "ZKFC IPC" }
        ]

## Packages

Install the "hadoop-hdfs-zkfc" service, symlink the rc.d startup script
in "/etc/init.d/hadoop-hdfs-datanode" and define its startup strategy.

      @call header: 'Packages', ->
        @service
          name: 'hadoop-hdfs-zkfc'
        @hdp_select
          name: 'hadoop-hdfs-namenode'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd Script'
          target: '/etc/init.d/hadoop-hdfs-zkfc'
          source: "#{__dirname}/../resources/hadoop-hdfs-zkfc.j2"
          local: true
          context: options: options
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-hdfs-zkfc.service'
            source: "#{__dirname}/../resources/hadoop-hdfs-zkfc-systemd.j2"
            local: true
            context: options: options
            mode: 0o0644
          @system.tmpfs
            header: 'Run dir'
            mount: options.pid_dir
            uid: options.user.name
            gid: options.hadoop_group.name
            perm: '0750'

## Configure

      @call header: 'Configure', ->
        @system.mkdir
          target: "#{options.conf_dir}"
        @hconfigure
          target: "#{options.conf_dir}/core-site.xml"
          properties: options.core_site
          backup: true
        @hconfigure
          target: "#{options.conf_dir}/hdfs-site.xml"
          source: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
          local: true
          properties: options.hdfs_site
          uid: options.user.name
          gid: options.hadoop_group.name
          backup: true
        @file.render
          header: 'Environment'
          target: "#{options.conf_dir}/hadoop-env.sh"
          source: "#{__dirname}/../resources/hadoop-env.sh.j2"
          local: true
          context:
            HADOOP_HEAPSIZE: options.hadoop_heap
            HADOOP_LOG_DIR: options.log_dir
            HADOOP_PID_DIR: options.pid_dir
            HADOOP_OPTS: options.hadoop_opts
            ZKFC_OPTS: options.opts
            java_home: options.java_home
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755
          backup: true
          eof: true
        @file
          header: 'Log4j'
          target: "#{options.conf_dir}/log4j.properties"
          source: "#{__dirname}/../resources/log4j.properties"
          local: true

## Kerberos

Create a service principal for the ZKFC daemon to authenticate with Zookeeper.
The principal is named after "zkfc/#{fqdn}@#{realm}" and its keytab
is stored as "/etc/security/keytabs/zkfc.service.keytab".

The Jaas file is registered as an Java property inside 'hadoop-env.sh' and is
stored as "/etc/hadoop/conf/zkfc.jaas"

      @call header: 'Kerberos', ->
        zkfc_principal = options.principal.replace '_HOST', options.fqdn
        nn_principal = options.nn_principal.replace '_HOST', options.fqdn
        @krb5.addprinc options.krb5.admin,
          principal: zkfc_principal
          keytab: options.keytab
          randkey: true
          uid: options.user.name
          gid: options.hadoop_group.name
          if: zkfc_principal isnt nn_principal
        @krb5.addprinc options.krb5.admin,
          principal: nn_principal
          keytab: options.nn_keytab
          randkey: true
          uid: options.user.name
          gid: options.hadoop_group.name
        @file.jaas
          target: options.jaas_file
          content: Client:
            principal: zkfc_principal
            keyTab: options.keytab
          uid: options.user.name
          gid: options.hadoop_group.name

## ZK Auth and ACL

Secure the Zookeeper connection with JAAS. In a Kerberos cluster, the SASL
provider is configured with the NameNode principal. The digest provider may also
be configured if the property "ryba.zkfc.digest.password" is set.

The permissions for each provider is "cdrwa", for example:

```
sasl:nn:cdrwa
digest:hdfs-zkfcs:KX44kC/I5PA29+qXVfm4lWRm15c=:cdrwa
```

Note, we didnt test a scenario where the cluster is not secured and the digest
isn't set. Probably the default acl "world:anyone:cdrwa" is used.

http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html#Securing_access_to_ZooKeeper

If you need to change the acl manually inside zookeeper, you can use this
command as an example:

```
setAcl /hadoop-ha sasl:zkfc:cdrwa,sasl:nn:cdrwa,digest:zkfc:ePBwNWc34ehcTu1FTNI7KankRXQ=:cdrwa
```

      @call header: 'ZK Auth and ACL', ->
        acls = []
        # acls.push 'world:anyone:r'
        jaas_user = /^(.*?)[@\/]/.exec(options.principal)?[1]
        acls.push "sasl:#{jaas_user}:cdrwa" if options.core_site['hadoop.security.authentication'] is 'kerberos'
        @file
          target: "#{options.conf_dir}/zk-auth.txt"
          content: if options.digest.password then "digest:#{options.digest.name}:#{options.digest.password}" else ""
          uid: options.user.name
          gid: options.group.name
          mode: 0o0700
        @system.execute
          cmd: """
          export ZK_HOME=/usr/hdp/current/zookeeper-client/
          java -cp $ZK_HOME/lib/*:$ZK_HOME/zookeeper.jar org.apache.zookeeper.server.auth.DigestAuthenticationProvider #{options.digest.name}:#{options.digest.password}
          """
          shy: true
          if: !!options.digest.password
        , (err, data) ->
          throw err if err
          return unless data.status
          digest = match[1] if match = /\->(.*)/.exec(data.stdout)
          throw Error "Failed to get digest" unless digest
          acls.push "digest:#{digest}:cdrwa"
        @call ->
          @file
            target: "#{options.conf_dir}/zk-acl.txt"
            content: acls.join ','
            uid: options.user.name
            gid: options.group.name
            mode: 0o0600

## SSH Fencing

Implement the SSH fencing strategy on each NameNode. To achieve this, the
"hdfs-site.xml" file is updated with the "dfs.ha.fencing.methods" and
"dfs.ha.fencing.ssh.private-key-files" properties.

For SSH fencing to work, the HDFS user must be able to log for each NameNode
into any other NameNode. Thus, the public and private SSH keys of the
HDFS user are deployed inside his "~/.ssh" folder and the
"~/.ssh/authorized_keys" file is updated accordingly.

We also make sure SSH access is not blocked by a rule defined
inside "/etc/security/access.conf". A specific rule for the HDFS user is
inserted if ALL users or the HDFS user access is denied.

      @call
        header: 'SSH Fencing'
      , ->
        @system.mkdir
          target: "#{options.user.home}/.ssh"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o700
        @file.download
          source: "#{options.ssh_fencing.private_key}"
          target: "#{options.user.home}/.ssh/id_rsa"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o600
        @file.download
          source: "#{options.ssh_fencing.public_key}"
          target: "#{options.user.home}/.ssh/id_rsa.pub"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o644
        @call (_, callback) ->
          fs.readFile null, "#{options.ssh_fencing.public_key}", (err, content) =>
            return callback err if err
            @file
              target: "#{options.user.home}/.ssh/authorized_keys"
              content: content
              append: true
              uid: options.user.name
              gid: options.hadoop_group.name
              mode: 0o600
            , (err, written) =>
              return callback err if err
              ssh = @ssh options.ssh
              fs.readFile ssh, '/etc/security/access.conf', 'utf8', (err, source) =>
                return callback err if err
                content = []
                # exclude = ///^\-\s?:\s?(ALL|#{options.user.name})\s?:\s?(.*?)\s*?(#.*)?$///
                # include = ///^\+\s?:\s?(#{options.user.name})\s?:\s?(.*?)\s*?(#.*)?$///
                exclude = /^\-\s?:\s?(ALL|#{options.user.name})\s?:\s?(.*?)\s*?(#.*)?$/
                include = /^\+\s?:\s?(#{options.user.name})\s?:\s?(.*?)\s*?(#.*)?$/
                included = false
                for line, i in source = source.split /\r\n|[\n\r\u0085\u2028\u2029]/g
                  if match = include.exec line
                    included = true # we shall also check if the ip/fqdn match in origin
                  if not included and match = exclude.exec line
                    content.push "+ : #{options.user.name} : #{options.nn_hosts}"
                  content.push line
                return callback null, false if content.length is source.length
                @file
                  target: '/etc/security/access.conf'
                  content: content.join '\n'
                .next callback

## HA Auto Failover

The action start by enabling automatic failover in "hdfs-site.xml" and configuring HA zookeeper quorum in
"core-site.xml". The impacted properties are "dfs.ha.automatic-failover.enabled" and
"ha.zookeeper.quorum". Then, we wait for all ZooKeeper to be started. Note, this is a requirement.

If this is an active NameNode, we format ZooKeeper and start the ZKFC daemon. If this is a standby
NameNode, we wait for the active NameNode to take leadership and start the ZKFC daemon.

      @call '@rybajs/metal/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      
      @system.execute
        header: 'Format ZK'
        if: [
          -> options.active_nn_host is options.fqdn
          -> options.automatic_failover
        ]
        cmd: "yes n | hdfs --config #{options.conf_dir} zkfc -formatZK"
        code_skipped: 2

## Dependencies

    fs = require 'ssh2-fs'
    mkcmd = require '../../lib/mkcmd'
