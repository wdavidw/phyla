
# Solr Cloud Docker Install

    module.exports = header: 'Solr Cloud Docker Install', handler: ({options}) ->
      tmp_dir  = options.tmp_dir ?= "/var/tmp/ryba/solr"
      options.build.dir = '/tmp/solr/build'

## Dependencies
      
      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/zookeeper/server/wait', once: true, options.wait_zookeeper_server
      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Identities

Create user and groups for solr user.

      @system.group header: "Group hadoop_group", options.hadoop_group
      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Layout

      @system.mkdir
        target: options.user.home
        uid: options.user.name
        gid: options.group.name
      @system.mkdir
        directory: options.conf_dir
        uid: options.user.name
        gid: options.group.name
      @system.mkdir
        target: options.user.home
        uid: options.user.name
        gid: options.group.name

## Kerberos

      # @krb5.addprinc options.krb5.admin,
      #   unless_exists: options.spnego.keytab
      #   header: 'Kerberos SPNEGO'
      #   principal: options.spnego.principal
      #   randkey: true
      #   keytab: options.spnego.keytab
      #   gid: options.hadoop_group.name
      #   mode: 0o660
      @system.execute
        header: 'SPNEGO'
        cmd: "su -l #{options.user.name} -c 'test -r #{options.spnego.keytab}'"
      @krb5.addprinc options.krb5.admin,
        header: 'Solr Super User'
        principal: options.admin_principal
        password: options.admin_password
        randkey: true
        uid: options.user.name
        gid: options.group.name
      @file.jaas
        header: 'Solr JAAS'
        target: "#{options.conf_dir}/solr-server.jaas"
        content:
          Client:
            principal: options.principal
            keyTab: options.keytab
            useKeyTab: true
            storeKey: true
            useTicketCache: true
        uid: options.user.name
        gid: options.group.name
      @krb5.addprinc options.krb5.admin,
        header: 'Solr Server User'
        principal: options.principal
        keytab: options.keytab
        randkey: true
        uid: options.user.name
        gid: options.group.name

## Container
Ryba support installing solr from apache official release or HDP Search repos.
Priority to docker pull function to get the solr container, else a tar should
be prepared in the nikita cache dir.

      @call header: 'Load Container', ->
        exists = false
        @docker.checksum
          docker: options.swarm_conf
          image: options.build.image
          tag: options.version
        , (err, status, checksum) ->
          throw err if err
          exists = checksum
        @docker.pull
          header: 'Pull container'
          if: -> not exists
          tag: options.build.image
          version: options.version
          code_skipped: 1
        @file.download
          unless: -> @status(-1) or @status(-2)
          binary: true
          header: 'Download container'
          source: options.build.source
          target: "#{tmp_dir}/solr.tar"
        @docker.load
          header: 'Load container to docker'
          unless: -> @status(-3)
          if_exists: "#{tmp_dir}/solr.tar"
          source: "#{tmp_dir}/solr.tar"
          docker: options.swarm_conf

## User Limits

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

## SSL

      @java.keystore_add
        keystore:  options.keystore.target
        storepass:  options.keystore.password
        caname: "hadoop_root_ca"
        key: "#{options.ssl.key.source}"
        cert: "#{options.ssl.cert.source}"
        keypass: options.keystore.password
        name: options.fqdn
        local: true
        uid: options.user.name
        gid: options.group.name
        mode: 0o0755
      @java.keystore_add
        keystore: options.truststore.target
        storepass: options.truststore.password
        caname: "hadoop_root_ca"
        cacert: "#{options.ssl.cacert.source}"
        local: options.ssl.cacert.local
        uid: options.user.name
        gid: options.group.name
        mode: 0o0755
      @call
        if: options.importCerts?
      , (_, cb) ->
        tmp_location = "/tmp/ryba_cacert_#{Date.now()}"
        {truststore} = options
        @each options.importCerts, ({options}, callback) ->
          {source, local, name} = options.value
          @file.download
            header: 'download cacert'
            source: source
            target: "#{tmp_location}/cacert"
            local: true
          @java.keystore_add
            header: "add cacert to #{name}"
            keystore: truststore.target
            storepass: truststore.password
            caname: name
            cacert: "#{tmp_location}/cacert"
          @next callback
        @system.remove
          target: tmp_location
        @next cb

## Cluster Specific configuration
Here we loop through the clusters definition to write container specific file
configuration like solr.in.sh or solr.xml.

      {clusters, hosts, fqdn, conf_dir, krb5, user, group, iptables} = options
      opts = options
      @each clusters, ({options}, callback) ->
        counter = 0
        name = options.key
        config = clusters[name] # get cluster config
        config_host = config.config_hosts["#{fqdn}"] # get host config for the cluster
        return callback() unless config_host?
        config_host.env['SOLR_AUTHENTICATION_OPTS'] ?= ''
        config_host.env['SOLR_AUTHENTICATION_OPTS'] += " -D#{k}=#{v} "  for k, v of config_host.auth_opts
        writes = for k,v of config_host.env
          match: RegExp "^.*#{k}=.*$", 'mg'
          replace: "#{k}=\"#{v}\" # RYBA DON'T OVERWRITE"
          append: true
        @tools.iptables
          if: iptables
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: config.port, protocol: 'tcp', state: 'NEW', comment: "Solr Cluster #{name}" }
          ]
        @krb5.addprinc krb5.admin,
          header: 'Cluster admin principal'
          principal: config.admin_principal
          password: config.admin_password
          randkey: true
          uid: user.name
          gid: group.name
        @system.mkdir
          header: 'Solr Cluster Configuration'
          target: "#{conf_dir}/clusters/#{name}"
          uid: user.name
          gid: group.name
          mode: 0o0750
        @system.mkdir
          header: 'Solr Cluster Log dir'
          target: config.log_dir
          uid: user.name
          gid: group.name
          mode: 0o0750
        @system.mkdir
          header: 'Solr Cluster Pid dir'
          target: config.pid_dir
          uid: user.name
          gid: group.name
          mode: 0o0750
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: config.pid_dir
          uid: user.name
          gid: group.name
          perm: '0750'
        @system.mkdir
          header: 'Solr Cluster Data dir'
          target: config.data_dir
          mode: 0o0750
        @system.chown
          target: config.data_dir
          uid: user.name
          gid: group.name
          mode: 0o0750
        @file
          header: 'Security config'
          content: JSON.stringify config_host.security
          target: "#{conf_dir}/clusters/#{name}/security.json"
          uid: user.name
          gid: group.name
          mode: 0o0750
        @file
          source:"#{__dirname}/../resources/cloud_docker/docker_entrypoint.sh.j2"
          target: "#{conf_dir}/clusters/#{name}/docker_entrypoint.sh"
          context: opts
          local: true
          backup: true
          uid: user.name
          gid: group.name
          mode: 0o0750
        @file.render
          source:"#{__dirname}/../resources/cloud_docker/zkCli.sh.j2"
          target: "#{conf_dir}/clusters/#{name}/zkCli.sh"
          context: opts
          local: true
          backup: true
          uid: user.name
          gid: group.name
          mode: 0o0750
        @file.render
          header: 'Solr Environment'
          source: "#{__dirname}/../resources/cloud/solr.ini.sh.j2"
          target: "#{conf_dir}/clusters/#{name}/solr.in.sh"
          context: opts
          write: writes
          local: true
          backup: true
          eof: true
          uid: user.name
          gid: group.name
          mode: 0o0750
        @call
          unless: (config.docker_compose_version is '1') or (not config.depends_on)
          shy: true
        , ->
          for node in [1..config.containers]
            config.service_def["node_#{node}"]['depends_on'] = ["node_#{config.master_node}"] if node != config.master_node
        @call
          header: 'Solr xml config'
        , ->
          for host in config.hosts
            root = builder.create('solr').dec '1.0', 'UTF-8', true
            solrcloud = root.ele 'solrcloud'
            solrcloud.ele 'str', {'name':'host'}, "#{fqdn}"
            solrcloud.ele 'str', {'name':'hostPort'}, "#{config.port}"
            solrcloud.ele 'str', {'name':'hostContext'}, '${hostContext:solr}'
            solrcloud.ele 'bool', {'name':'genericCoreNodeNames'}, '${genericCoreNodeNames:true}'
            solrcloud.ele 'str', {'name':'zkCredentialsProvider'}, "#{config_host.zk_opts.zkCredentialsProvider}"
            solrcloud.ele 'str', {'name':'zkACLProvider'}, "#{config_host.zk_opts.zkACLProvider}"
            solrcloud.ele 'int', {'name':'zkClientTimeout'}, '${zkClientTimeout:30000}'
            solrcloud.ele 'int', {'name':'distribUpdateSoTimeout'}, '${distribUpdateSoTimeout:600000}'
            solrcloud.ele 'int', {'name':'distribUpdateConnTimeout'}, '${distribUpdateConnTimeout:60000}'
            solrcloud.ele 'str', {'name':'zkHost'}, "#{config_host['env']['ZK_HOST']}"
            shardHandlerFactory = solrcloud.ele 'shardHandlerFactory', {'name':'shardHandlerFactory','class':'HttpShardHandlerFactory'}
            shardHandlerFactory.ele 'int', {'name':'socketTimeout'}, '${socketTimeout:600000}'
            shardHandlerFactory.ele 'int', {'name':'connTimeout'}, '${connTimeout:60000}'
            @file
              if: host is fqdn
              header: 'Solr Config'
              target: "#{conf_dir}/clusters/#{name}/solr.xml"
              uid: user.name
              gid: group.name
              content: root.end pretty:true
              mode: 0o0750
              backup: true
              eof: true
            @file.render
              if: host is fqdn
              header: 'Log4j'
              source: "#{__dirname}/../resources/log4j.properties.j2"
              target: "#{conf_dir}/clusters/#{name}/log4j.properties"
              context: options
              local: true
            @call
              header: "Dockerfile"
            , ->
              dockerfile = null
              switch config.docker_compose_version
                when '1'
                  dockerfile = clusters[name].service_def
                  break;
                when '2'
                  dockerfile =
                    version:'2'
                    services: clusters[name].service_def
                  break;
              @call ->
                @file.yaml
                  if: fqdn is config['master'] or not options.swarm_conf?
                  target: "#{conf_dir}/clusters/#{name}/docker-compose.yml"
                  content: dockerfile
                  uid: user.name
                  gid: group.name
                  mode: 0o0750
        @docker.compose.up
          header: 'Compose up through swarm'
          if: fqdn is config['master'] and options.swarm_conf?
          target: "#{conf_dir}/clusters/#{name}/docker-compose.yml"
        @docker.compose.up
          header: 'Compose up without swarm'
          docker: options.docker
          unless: options.swarm_conf?
          services: "node_#{hosts.indexOf(fqdn)+1}"
          target: "#{conf_dir}/clusters/#{name}/docker-compose.yml"
        @next callback

## Dependencies

    path = require 'path'
    mkcmd  = require '../../lib/mkcmd'
    builder = require 'xmlbuilder'
