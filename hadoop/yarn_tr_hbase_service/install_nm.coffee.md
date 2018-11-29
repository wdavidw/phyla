
# Hadoop YARN Timeline Reader Install

The Timeline Reader is a stand-alone server daemon and doesn't need to be
co-located with any other service.

    module.exports = header: 'YARN TR HBase Service NM Install', handler: ({options}) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'
      @registry.register ['hdfs','put'], 'ryba/lib/actions/hdfs/put'
      @registry.register ['hdfs','chown'], 'ryba/lib/actions/hdfs/chown'
      @registry.register ['hdfs','mkdir'], 'ryba/lib/actions/hdfs/mkdir'      
      @registry.register 'ranger_policy', 'ryba/ranger/actions/ranger_policy'

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
      @call once: true, 'ryba/hadoop/hdfs_nn/wait', options.wait_hdfs_nn, conf_dir: '/etc/hadoop/conf'

## IPTables

| Service   | Port   | Proto     | Parameter                                  |
|-----------|------- |-----------|--------------------------------------------|
| timeline  | 10200  | tcp/http  | yarn.timeline-service.address              |
| timeline  | 8188   | tcp/http  | yarn.timeline-service.reader.webapp.address       |
| timeline  | 8190   | tcp/https | yarn.timeline-service.reader.webapp.https.address |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).


      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.master.port'], protocol: 'tcp', state: 'NEW', comment: "Yarn HBase Master RPC" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.master.info.port'], protocol: 'tcp', state: 'NEW', comment: "Yarn HBase Master HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.regionserver.port'], protocol: 'tcp', state: 'NEW', comment: "Yarn HBase RS RPC" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.hbase_site['hbase.regionserver.info.port'], protocol: 'tcp', state: 'NEW', comment: "Yarn HBase RS HTTP" }
        ]

## Service

Install the "hadoop-yarn-timelineserver" service, symlink the rc.d startup script
in "/etc/init.d/hadoop-hdfs-datanode" and define its startup strategy.

      @system.tmpfs
        header: 'Run dir'
        mount: "#{options.pid_dir}"
        uid: options.ats_user.name
        gid: options.hadoop_group.name
        perm: '0775'

# Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: "#{options.conf_dir}"
        @system.mkdir
          target: "#{options.pid_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o775
        @system.mkdir
          target: "#{options.log_dir}"
          uid: options.user.name
          gid: options.hadoop_group.name
          parent: true

## Kerberos

Create the Kerberos service principal by default in the form of
"yarn-ats-hbase/{host}@{realm}" and place its keytab inside
"/etc/security/keytabs/yarn-ats.hbase-master.service.keytab" with ownerships set to
"mapred:hadoop" and permissions set to "0600".

      @krb5.addprinc options.krb5.admin,
        header: 'hbase ats rs'
        principal: options.hbase_site['hbase.regionserver.kerberos.principal'].replace '_HOST', options.fqdn
        randkey: true
        keytab: options.hbase_site['hbase.regionserver.keytab.file']
        uid: options.ats_user.name
        gid: options.ats_group.name
        mode: 0o0600
      @system.copy
        header: 'hbase ats master'
        source: options.hbase_site['hbase.regionserver.keytab.file']
        target: options.hbase_site['hbase.master.keytab.file']
        mode: 0o0600
        uid: options.ats_user.name
        gid: options.ats_group.name     


## Kerberos JAAS

The JAAS file is used by the ResourceManager to initiate a secure connection 
with Zookeeper.

      @file.jaas
        header: 'Kerberos HBase Master JAAS'
        target: "#{options.conf_dir}/yarn_hbase_master_jaas.conf"
        content: 
          Client:
            principal: options.hbase_site['hbase.master.kerberos.principal'].replace '_HOST', options.fqdn
            keyTab: options.hbase_site['hbase.master.keytab.file']
          'com.sun.security.jgss.krb5.initiate':
            principal: options.hbase_site['hbase.master.kerberos.principal'].replace '_HOST', options.fqdn
            keyTab: options.hbase_site['hbase.master.keytab.file']
        uid: options.ats_user.name
        gid: options.ats_group.name
        mode: 0o600
        gid: options.hadoop_group.name
      @file.jaas
        header: 'Kerberos HBase RS JAAS'
        target: "#{options.conf_dir}/yarn_hbase_regionserver_jaas.conf"
        content: 
          Client:
            principal: options.hbase_site['hbase.regionserver.kerberos.principal'].replace '_HOST', options.fqdn
            keyTab: options.hbase_site['hbase.regionserver.keytab.file']
          'com.sun.security.jgss.krb5.initiate':
            principal: options.hbase_site['hbase.regionserver.kerberos.principal'].replace '_HOST', options.fqdn
            keyTab: options.hbase_site['hbase.regionserver.keytab.file']
        uid: options.ats_user.name
        gid: options.ats_group.name
        mode: 0o600
