
# Configure SolrCloud Clusters

This module enable adminstrator to instantiate several solrcloud clusters.
The clusters are described in `options.clusters` property.
Example of config for a solr cluster.
The Settings for each solr node in a solrcloud cluster will be the same.

Implementation details:

* We use the host network when running the container, because of hostname mapping 
when spnego principal is created.
* Can not start more than one container on the same host becausewe are using
network_mode: host (port collision).

```cson
"ryba_snapshot":
  containers: 2
  master: 'master1.ryba'
  hosts: ['master1.ryba', 'master2.ryba', 'master3.ryba']
  env:
    'SOLR_JAVA_HOME': '/user/java/jre'
  security:
    'authorization': 
      'class': 'solr.RuleBasedAuthorizationPlugin'
  data_dir: '/var/my_data_dir'
  log_dir: '/var/log/solr/ryba_snapshot'
  pid_dir: '/var/run/solr/solr.pid'
  heap_size: '1024m'
  port: 10000
  zk_node: 'my_cluster'
  only: true    
```

Makes this method public to let other services use its configuration logic (ranger for example)
You can check the [docker-compose file reference](https://docs.docker.com/compose/compose-file/)
Note: October 2017
Make configuration options more restrictive
  - hosts are required

      module.exports = (options, name, config={}) ->
        config.hosts ?= options.hosts
        throw Error "Malformed Master for cluster: #{name}" unless config.hosts.indexOf config['master'] > -1
        throw Error "Missing port for cluster: #{name}"  unless config.port?
        throw Error "Name should not contain -" if /-+/.test name
        # Cluster config 
        # Docker-compose config
        config.name ?= name
        config.hosts = config.hosts.slice(0,config.containers) if config.containers isnt config.hosts.length
        config.docker_compose_version ?= options.docker_compose_version ?= '1'
        config.mem_limit ?= '1g'
        config.port ?= '8983'
        # config.cpu_shares ?= 5
        # config.cpu_quota ?= 50 * 1000
        config.is_ssl_enabled ?= true
        config.heap_size ?= '1024m'
        config.data_dir ?= "#{options.user.home}/#{name}"
        config.log_dir ?= "#{options.log_dir}/#{name}"
        config.pid_dir ?= "#{options.pid_dir}/#{name}"
        config.zk_node ?= "solr_#{name}"
        config.zk_connect ?= "#{options.zk_connect}"
        config.zk_urls ?= "#{options.zk_connect}/#{config.zk_node}"
        config.admin_principal ?= options.admin_principal
        config.admin_password ?= options.admin_password
        config.conf_dir ?= "#{options.conf_dir}/clusters/#{name}"
        config.solr_urls ?= config.hosts.map( (host) -> "#{if config.is_ssl_enabled  then 'https://' else 'http://'}#{host}:#{config['port']}").join(',')
        config.authentication_class ?= options.security["authentication"]['class']
        config.authorization_class ?= 'solr.RuleBasedAuthorizationPlugin'
        config.service_def ?= {}
        config['env'] ?= {}
        ## allow administrators to disable ssl on solr cloud docker clusters.
        config['env']['SSL_ENABLED'] = "#{config.is_ssl_enabled}"
        config['env']['SOLR_HEAP'] ?= config.heap_size
        volumes = [
            "#{config.conf_dir}/docker_entrypoint.sh:/docker_entrypoint.sh",
            "#{options.conf_dir}/keystore:#{options.conf_dir}/keystore",
            "#{options.conf_dir}/truststore:#{options.conf_dir}/truststore",
            "#{options.conf_dir}/solr-server.jaas:#{options.conf_dir}/solr-server.jaas",
            "#{config.conf_dir}/solr.in.sh:#{options.conf_dir}/solr.in.sh",
            "#{config.conf_dir}/solr.xml:#{options.conf_dir}/solr.xml",
            "#{config.data_dir}:/var/solr/data",
            "#{config.log_dir}:#{options.log_dir}",
            "/etc/security/keytabs:/etc/security/keytabs",
            "#{config.conf_dir}/zkCli.sh:/usr/solr-cloud/current/server/scripts/cloud-scripts/zkcli.sh",
            "/etc/krb5.conf:/etc/krb5.conf" ] 
        volumes.push config.volumes...
        config.master_configured = false
        # Custom Host config (a container for a host)
        config_hosts = config.config_hosts = {}
        for n, host of config.hosts
            node = parseInt(n)+1
            command = "/docker_entrypoint.sh --zk_node #{config.zk_node} " # --port #{config.port}"
            environment = []
            # `affinity:container` enables docker to start a new container on a host 
            # where no other container belonging to the cluster is already running.
            environment.push "affinity:container!=*#{name.split('_').join('')}_node*"
            environment.push "SSL_ENABLED=true" if config.is_ssl_enabled
            container_name = "node_#{node}"
            # We need to set master property to now which server will launch bootstrap
            # command and get it's node name (solr node inside a container for a cluster).
            if config['master'] is host
              #we configure this name generally but only needed for solr collection from ranger install
              config.master_container_runtime_name ?= "#{name.split('_').join('')}_#{container_name}_1"
              # --bootstrap args in commands enable master to create the zookeeper 
              # node for the current cluster. Check docker_entrypoint.sh file for more infos.
              command += " --bootstrap"
              config.master_node = node
              config.master_configured = true
              config.master_container_name = container_name
            #docker-compose.yml container specific properties
            #be careful this property is used in `ryba/ranger/admin/solr_bootstrap` file
            switch config.docker_compose_version
              when '1'
                config.service_def[container_name]=
                  'image' : "#{options.build.image}:#{options.version}"
                  # 'restart': "always"
                  'command': command
                  'volumes': volumes
                  'ports': [config.port]
                  'net': 'host'
                  'mem_limit': config.mem_limit
                  'cpu_shares': config.cpu_shares
                  'cpu_quota': config.cpu_quota
                config.service_def[container_name]['environment'] = environment if  environment.length > 0
              when '2'
                config.service_def[container_name]=
                  'image' : "#{options.build.image}:#{options.version}"
                  # 'restart': "always"
                  'command': command
                  'volumes': volumes
                  'ports': [config.port]
                  'network_mode': 'host'
                  'mem_limit': config.mem_limit
                  'cpu_shares': config.cpu_shares
                  'cpu_quota': config.cpu_quota
                config.service_def[container_name]['environment'] = environment if  environment.length > 0
              else 
                throw Error 'Docker compose version not supported'
            config_host = config_hosts["#{host}"] ?= {}
            # Configure host environment config
            config_host['env'] ?= {}
            config_host['env']['SOLR_HOME'] ?= "#{options.user.home}"
            config_host['env']['SOLR_PORT'] ?= "#{config.port}"
            config_host['env']['SOLR_HOST'] ?= "#{host}"
            config_host['env']['SOLR_HEAP'] ?= config.env['SOLR_HEAP']
            config_host['env']['SOLR_AUTHENTICATION_OPTS'] ?= "-Djetty.port=#{config.port}" #backward compatibility
            config_host['env']['ZK_HOST'] ?= "#{options.zk_connect}/#{config.zk_node}"
            props = [
              'SOLR_JAVA_HOME'
              'SOLR_PID_DIR'
              'ENABLE_REMOTE_JMX_OPTS'
              # 'SOLR_AUTH_TYPE'
            ]
            if config.is_ssl_enabled
              props.push [
                'SOLR_SSL_KEY_STORE'
                'SOLR_SSL_KEY_STORE_PASSWORD'
                'SOLR_SSL_TRUST_STORE'
                'SOLR_SSL_TRUST_STORE_PASSWORD'
                'SOLR_SSL_NEED_CLIENT_AUTH'
              ]...
            for prop in props then config_host['env'][prop] ?= config_host['env'][prop] ?= config['env'][prop] ?= options['env'][prop]
            # Authentication & Authorization
            config_host.security = config.security ?= {}
            config_host.security["authentication"] ?= {}
            config_host.security["authentication"]['class'] ?= config.authentication_class
            config_host.security['authentication']['blockUnknown'] ?= true 
            # ACLs
            config_host.security["authorization"] ?= {}
            config_host.security["authorization"]['class'] ?= config.authorization_class
            config_host.security["authorization"]['permissions'] ?= []
            config_host.security["authorization"]['permissions'].push name: 'security-edit' , role: 'admin' unless config_host.security["authorization"]['permissions'].filter( (perm) -> return perm if perm['name']?).length > 0 #define new role 
            # config_host.security["authorization"]['permissions'].push name: 'read' , role: 'reader' unless config_host.security["authorization"]['permissions'].indexOf({name: 'read' , role: 'reader' }) > -1  #define new role
            # config_host.security["authorization"]['permissions'].push name: 'all' , role: 'manager' unless config_host.security["authorization"]['permissions'].indexOf({name: 'all' , role: 'manager' }) > -1  #define new role
            config_host.security["authorization"]['user-role'] ?= {}
            config_host.zk_opts ?= {}
            # # This lets define your credentials using system properties.
            config_host.zk_opts['zkACLProvider'] ?= 'org.apache.solr.common.cloud.DefaultZkACLProvider'
            config_host.zk_opts['zkCredentialsProvider'] ?= 'org.apache.solr.common.cloud.DefaultZkCredentialsProvider'
            if config_host.security["authentication"]['class'] is 'org.apache.solr.security.KerberosPlugin'
              config_host['env']['SOLR_AUTHENTICATION_CLIENT_CONFIGURER'] ?= 'org.apache.solr.client.solrj.impl.Krb5HttpClientConfigurer' 
              # Control ACL with  SASL Authentication
              # config_host.zk_opts['zkCredentialsProvider'] ?= 'org.apache.solr.common.cloud.VMParamsSingleSetCredentialsDigestZkCredentialsProvider'
              # config_host.zk_opts['zkACLProvider'] ?= 'org.apache.solr.common.cloud.SaslZkACLProvider'
              config_host.security["authorization"]['user-role']["#{config.admin_principal}"] ?= 'manager'
              config_host.zk_opts['solr.authorization.superuser'] ?= options.user.name #default to solr
              for host in config.hosts
                config_host.security["authorization"]['user-role']["#{options.user.name}/#{host}@#{options.krb5.realm}"] ?= 'manager'
                config_host.security["authorization"]['user-role']["HTTP/#{host}@#{options.krb5.realm}"] ?= 'manager'
            else
              # Control ACL with auth/digest
              # config_host.zk_opts['zkCredentialsProvider'] ?= 'org.apache.solr.common.cloud.VMParamsSingleSetCredentialsDigestZkCredentialsProvider'
              # config_host.zk_opts['zkACLProvider'] ?= 'org.apache.solr.common.cloud.VMParamsAllAndReadonlyDigestZkACLProvider'
              config_host.env['SOLR_ZK_CREDS_AND_ACLS'] ?= "-DzkDigestUsername=admin-user -DzkDigestPassword=admin-password"
              config_host.env['SOLR_ZK_CREDS_AND_ACLS'] +=  " -DzkDigestReadonlyUsername=readonly-user -DzkDigestReadonlyPassword=readonly-password"
              # Create solr:SolrRocks by default
              config_host.security['authentication']['credentials'] ?= {} 
              config_host.security['authentication']['credentials']['solr'] ='IV0EHq1OnNrj6gvRCwvFwTrZ1+z1oBbnQdiVC3otuq0= Ndd7LKvVBAaZIF0QAVi1ekCfAJXr1GGfLtRUXhgrF8c='
              # Gives it admin role
              config_host.security["authorization"]['user-role']['solr'] ?= 'admin'
            # Env opts
            config_host.auth_opts ?= {}
            config_host.auth_opts['solr.kerberos.cookie.domain'] = "#{config_host['env']['SOLR_HOST']}"
            config_host.auth_opts['java.security.auth.login.config'] ?= "#{options.conf_dir}/solr-server.jaas"
            config_host.auth_opts['solr.kerberos.principal'] = "HTTP/#{config_host['env']['SOLR_HOST']}@#{options.krb5.realm}"
            config_host.auth_opts['solr.kerberos.keytab'] ?= options.spnego.keytab
            config_host.auth_opts['solr.kerberos.name.rules'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
        return config

## Dependencies

      # rangerize = require "#{__dirname}/../../ranger/plugins/solr_cloud_docker/rangerize"
