
# Hadoop HDFS SecondaryNameNode Install

    module.exports = header: 'HDFS SNN', handler: ({options}) ->

## Register

      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'

## IPTables

| Service    | Port | Proto  | Parameter                  |
|------------|------|--------|----------------------------|
| namenode  | 9870  | tcp    | dfs.namdnode.http-address  |
| namenode  | 9871  | tcp    | dfs.namenode.https-address |
| namenode  | 8020  | tcp    | fs.defaultFS               |
| namenode  | 8019  | tcp    | dfs.ha.zkfc.port           |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      [_, http_port] = options.hdfs_site['dfs.namenode.secondary.http-address'].split ':'
      [_, https_port] = options.hdfs_site['dfs.namenode.secondary.https-address'].split ':'
      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: http_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: https_port, protocol: 'tcp', state: 'NEW', comment: "HDFS SNN HTTPS" }
        ]

## Service

Install the "hadoop-hdfs-secondarynamenode" service, symlink the rc.d startup
script inside "/etc/init.d" and activate it on startup.

      @call header: 'Service', ->
        @service
          name: 'hadoop-hdfs-secondarynamenode'
        @hdp_select
          name: 'hadoop-hdfs-client' # Not checked
          name: 'hadoop-hdfs-secondarynamenode'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd script'
          target: '/etc/init.d/hadoop-hdfs-secondarynamenode'
          source: "#{__dirname}/../resources/secondarynamenode.j2"
          local: true
          context: context: context
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-hdfs-secondarynamenode.service'
            source: "#{__dirname}/../resources/hadoop-hdfs-secondarynamenode-systemd.j2"
            local: true
            context: context: context
            mode: 0o0644
          @system.tmpfs
            mount: "#{options.pid_dir}"
            uid: options.user.name
            gid: options.hadoop_group.name
            perm: '0755'

      @call header: 'Layout', ->
        @system.mkdir
          target: for dir in options.hdfs_site['dfs.namenode.checkpoint.dir'].split ','
            if dir.indexOf('file://') is 0
            then dir.substr(7) else dir
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{options.pid_dir.replace '$USER', options.user.name}"
          uid: options.user.name
          gid: options.hadoop_group.name
          mode: 0o755
        @system.mkdir
          target: "#{options.log_dir}"
          uid: options.user.name
          gid: options.group.name
          parent: true

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.hdfs_site['dfs.secondary.namenode.kerberos.principal']
        randkey: true
        keytab: options.hdfs_site['dfs.secondary.namenode.keytab.file']
        uid: options.user.name
        gid: options.hadoop_group.name

# Configure

      @file.types.hfile
        header: 'Configuration'
        target: "#{options.conf_dir}/hdfs-site.xml"
        source: "#{__dirname}/../../resources/core_hadoop/hdfs-site.xml"
        local: true
        properties: options.hdfs_site
        uid: options.user.name
        gid: options.hadoop_group.name
        backup: true
