
# Install Apache YARN DNS Registry
Its not mqndqtory but adviced to install the yarn dns registry, if you attend to use yarn 3
new service features, as it enable to keep track of long running application on the cluster.

    module.exports = header: 'YARN DNS Registry', handler: ({options}) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Identities

By default, the "hadoop-yarn-timelineserver" package create the following entries:

```bash
cat /etc/passwd | grep yarn
yarn:x:2403:2403:Hadoop YARN User:/var/lib/hadoop-yarn:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:499:hdfs
```

      @system.group header: 'Hadoop Group', options.hadoop_group
      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Wait

      @call once: true, 'masson/core/krb5_client/wait', options.wait_krb5_client

## IPTables

| Service   | Port   | Proto     | Parameter                                  |
|-----------|------- |-----------|--------------------------------------------|
| registry  | 5353   | tcp/http  | hadoop.registry.dns.bind-port              |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.yarn_site['hadoop.registry.dns.bind-port'], protocol: 'tcp', state: 'NEW', comment: "Yarn Registry PORT" }
        ]

## Service

Install the "hadoop-yarn-timelineserver" service, symlink the rc.d startup script
in "/etc/init.d/hadoop-hdfs-datanode" and define its startup strategy.

      @call header: 'Service', ->
        @service
          name: 'hadoop-yarn-registrydns'
        @hdp_select
          name: 'hadoop-yarn-registrydns' # Not checked
        @service.init
          header: 'Systemd Script'
          target: '/usr/lib/systemd/system/hadoop-yarn-registrydns.service'
          source: "#{__dirname}/../resources/hadoop-yarn-registrydns-systemd.j2"
          local: true
          context: options: options
          mode: 0o0644
        @system.tmpfs
          header: 'Run dir'
          mount: "#{options.pid_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          perm: '0755'

# Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: "#{options.conf_dir}"
        @system.mkdir
          target: "#{options.pid_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{options.log_dir}"
          uid: options.user.name
          gid: options.group.name
          parent: true


## Configuration

Update the "yarn-site.xml" configuration file.

      @hconfigure
        header: 'Core Site'
        target: "#{options.conf_dir}/core-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/core-site.xml"
        local: true
        properties: options.core_site
        backup: true
      @hconfigure
        header: 'HDFS Site'
        target: "#{options.conf_dir}/hdfs-site.xml"
        properties: options.hdfs_site
        backup: true
      @hconfigure
        header: 'YARN Site'
        target: "#{options.conf_dir}/yarn-site.xml"
        properties: options.yarn_site
        backup: true
      @file
        header: 'Log4j'
        target: "#{options.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
      @call header: 'Environment', ->
        YARN_REGISTRYDNS_OPTS = options.opts.base
        YARN_REGISTRYDNS_OPTS += " -D#{k}=#{v}" for k, v of options.opts.java_properties
        YARN_REGISTRYDNS_OPTS += " #{k}#{v}" for k, v of options.opts.jvm
        @file.render
          target: "#{options.conf_dir}/yarn-env.sh"
          source: "#{__dirname}/../resources/yarn-env.sh.j2"
          local: true
          context:
            security_enabled: options.krb5.realm?
            hadoop_yarn_home: options.yarn_home
            java64_home: options.java_home
            yarn_log_dir: options.log_dir
            yarn_pid_dir: options.pid_dir
            hadoop_libexec_dir: ''
            hadoop_java_io_tmpdir: "#{options.log_dir}/tmp"
            yarn_heapsize: options.heapsize
            yarn_registry_dns_jaas_file: "#{options.conf_dir}/yarn-registry.jaas"
            # ryba options
            YARN_REGISTRYDNS_OPTS: YARN_REGISTRYDNS_OPTS
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o0755
          backup: true
      @file.render
        header: 'Env'
        target: "#{options.conf_dir}/hadoop-env.sh"
        source: "#{__dirname}/../resources/hadoop-env.sh.j2"
        local: true
        context:
          HADOOP_LOG_DIR: options.log_dir
          HADOOP_PID_DIR: options.pid_dir
          java_home: options.java_home
        uid: options.user.name
        gid: options.hadoop_group.name
        mode: 0o750
        backup: true
        eof: true

## Kerberos

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.krb5.principal.replace '_HOST', options.fqdn
        randkey: true
        keytab: options.krb5.keytab
        uid: options.user.name
        gid: options.hadoop_group.name

## Kerberos JAAS

The JAAS file is used by the ResourceManager to initiate a secure connection 
with Zookeeper.

      @file.jaas
        header: 'Kerberos JAAS'
        target: "#{options.conf_dir}/yarn-registry.jaas"
        content: Client:
          principal: options.krb5.principal.replace '_HOST', options.fqdn
          keyTab: options.krb5.keytab
        uid: options.user.name
        gid: options.hadoop_group.name

# 
# ## SSL
# 
#       @call header: 'SSL', ->
#         @hconfigure
#           target: "#{options.conf_dir}/ssl-server.xml"
#           properties: options.ssl_server
#         @hconfigure
#           target: "#{options.conf_dir}/ssl-client.xml"
#           properties: options.ssl_client
#         # Client: import certificate to all hosts
#         @java.keystore_add
#           keystore: options.ssl_client['ssl.client.truststore.location']
#           storepass: options.ssl_client['ssl.client.truststore.password']
#           caname: "hadoop_root_ca"
#           cacert: options.ssl.cacert.source
#           local: options.ssl.cacert.local
#         # Server: import certificates, private and public keys to hosts with a server
#         @java.keystore_add
#           keystore: options.ssl_server['ssl.server.keystore.location']
#           storepass: options.ssl_server['ssl.server.keystore.password']
#           key: options.ssl.key.source
#           cert: options.ssl.cert.source
#           keypass: options.ssl_server['ssl.server.keystore.keypassword']
#           name: options.ssl.key.name
#           local: options.ssl.key.local
#         @java.keystore_add
#           keystore: options.ssl_server['ssl.server.keystore.location']
#           storepass: options.ssl_server['ssl.server.keystore.password']
#           caname: "hadoop_root_ca"
#           cacert: options.ssl.cacert.source
#           local: options.ssl.cacert.local
# 
# ## Kerberos
# 
# Create the Kerberos service principal by default in the form of
# "ats/{host}@{realm}" and place its keytab inside
# "/etc/security/keytabs/ats.service.keytab" with ownerships set to
# "mapred:hadoop" and permissions set to "0600".
# 
#       @krb5.addprinc options.krb5.admin,
#         header: 'Kerberos'
#         principal: options.yarn_site['yarn.timeline-service.principal'].replace '_HOST', options.fqdn
#         randkey: true
#         keytab: options.yarn_site['yarn.timeline-service.keytab']
#         uid: options.user.name
#         gid: options.group.name
#         mode: 0o0600
