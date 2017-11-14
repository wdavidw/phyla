
# Hadoop KMS Install

    module.exports = header: 'Hadoop KMS Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service  | Port  | Proto | Parameter                  |
| -------- | ----- | ----- | -------------------------- |
| kms      | 16000 | tcp   |                            |
| kms      | 16001 | tcp   |                            |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.http_port, protocol: 'tcp', state: 'NEW', comment: "KMS HTTP" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.admin_port, protocol: 'tcp', state: 'NEW', comment: "KMS Admin" }
        ]

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Packages

      @call header: 'Packages', ->
        @service
          name: 'hadoop-mapreduce'
        @hdp_select
          name: 'hadoop-client'
        @system.execute
          cmd: """
          version=`ls -l /usr/hdp/current/hadoop-mapreduce-client | sed 's/.*-> \\/usr\\/hdp\\/\\(.*\\)\\/.*/\\1/g'`
          if [ -z "$version" ]; then echo 'Version not found' && exit 1; fi
          echo version is $version
          if [ -d /usr/hdp/$version/hadoop-kms ]; then exit 3; fi
          mkdir -p /usr/hdp/$version/hadoop-kms
          tar xzf /usr/hdp/$version/hadoop/mapreduce.tar.gz --strip-components=1 -C /usr/hdp/$version/hadoop-kms
          chown -R #{options.user.name}:#{options.group.name} /usr/hdp/$version/hadoop-kms
          ln -sf /usr/hdp/$version/hadoop-kms /usr/hdp/current/hadoop-kms
          """
          trap: true
          code_skipped: 3
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Initd Script'
          target: "/etc/init.d/hadoop-kms"
          source: "#{__dirname}/../resources/hadoop-kms.j2"
          local: true
          context: options: options
          mode: 0o0755
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hadoop-kms.service'
            source: "#{__dirname}/../resources/hadoop-kms-systemd.j2"
            local: true
            context: options: options
            mode: 0o0644
          @system.tmpfs
            mount: "#{options.pid_dir}"
            uid: options.user.name
            gid: options.group.name
            perm: '0755'

## Layout

      @system.mkdir
        header: 'Layout PID'
        target: "#{options.pid_dir}"
        uid: options.user.name
        gid: options.group.name
        mode: 0o0755
      @system.mkdir
        header: 'Layout Log'
        target: "#{options.log_dir}" #/#{options.user.name}
        uid: options.user.name
        gid: options.group.name
        parent: true

## Environment

Maintain the "kms-env.sh" file.

      @file.render
        header: 'Environment'
        target: "#{options.conf_dir}/kms-env.sh"
        source: "#{__dirname}/../resources/kms-env.sh.j2"
        local: true
        context: options: options
        uid: options.user.name
        gid: options.hadoop_group.name
        mode: 0o755
        backup: true
        eof: true

## Configuration

      @hconfigure
        header: 'Configuration'
        target: "#{options.conf_dir}/kms-site.xml"
        properties: options.kms_site
        uid: options.user.name
        gid: options.user.name
        backup: true
      @hconfigure
        header: 'ACLs'
        target: "#{options.conf_dir}/kms-acls.xml"
        properties: options.acls
        uid: options.user.name
        gid: options.user.name
        backup: true

## Java KeyStore

      # Server: import certificates, private and public keys to hosts with a server
      @file
        target: "#{options.kms_site['hadoop.security.keystore.java-keystore-provider.password-file']}"
        content: options.ssl.password
      @java.keystore_add
        keystore: options.kms_site['hadoop.kms.key.provider.uri'].split('@')[1]
        storepass: 'lululu'
        key: options.ssl.key.source
        cert: options.ssl.cert.source
        keypass: options.ssl.password
        name: options.ssl.key.name
        local: options.ssl.key.local
      @java.keystore_add
        keystore: options.kms_site['hadoop.kms.key.provider.uri'].split('@')[1]
        storepass: 'lululu'
        caname: "hadoop_root_ca"
        cacert: options.ssl.cacert.source
        local: options.ssl.cacert.local
