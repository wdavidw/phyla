
# Configure JMX Exporter Yarn NodeManager

    module.exports = (service) ->
      options = service.options

## Identities

      options.hadoop_group = service.deps.hadoop_core.options.hadoop_group
      # Group
      options.group ?= mixme service.deps.prometheus_monitor[0].options.group, options.group
      options.user ?= mixme service.deps.prometheus_monitor[0].options.user, options.user
      options.yarn_user ?= mixme service.deps.yarn_nm.options.user
      options.yarn_group ?= mixme service.deps.yarn_nm.options.group

## Configuration Layout

      options.conf_dir ?= "/etc/prometheus-exporter-jmx/conf"
      options.java_home ?= service.deps.java.options.java_home
      options.conf_file ?= "#{options.conf_dir}/yarn_nodemanager.yaml"
      
## Package
    
      options.version ?= '0.1.0'
      #standalone server
      options.jar_source ?= "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_httpserver/#{options.version}/jmx_prometheus_httpserver-#{options.version}-jar-with-dependencies.jar"
      # java agent
      # options.agent_source ?= "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/#{options.version}/jmx_prometheus_javaagent-#{options.version}.jar"
      options.download = service.deps.jmx_exporter[0].node.fqdn is service.node.fqdn
      options.install_dir ?= "/usr/prometheus/#{options.version}/jmx_exporter"
      options.opts ?= {}
      options.opts.base ?= ''
      options.opts.java_properties ?= {}
      options.opts.jvm ?= {}

## Enable JMX Server
JMX options will be configured using a properties file, more readable for administrators.
There is a difference between  -Dcom.sun.management.config.file=<file>. and
com.sun.management.jmxremote.ssl.config.file=<file>.

      options.jmx_config_file ?= "#{service.deps.yarn_nm.options.conf_dir}/jmx.properties"
      service.deps.yarn_nm.options.opts.java_properties['com.sun.management.config.file'] ?= options.jmx_config_file
      options.jmx_config ?= {}
      options.jmx_config['com.sun.management.jmxremote'] ?= 'true'
      options.jmx_config['com.sun.management.jmxremote.port'] ?= '9015'
      options.jmx_config['com.sun.management.jmxremote.ssl.config.file'] ?= "#{service.deps.yarn_nm.options.conf_dir}/jmx-ssl.properties"

## Enable JMX SSL

      options.ssl = mixme service.deps.ssl, service.deps.yarn_nm.options.ssl
      if !!options.ssl
        options.jmx_ssl_file ?= options.jmx_config['com.sun.management.jmxremote.ssl.config.file']
        options.jmx_ssl_config ?= {}
        service.deps.yarn_nm.options.opts.java_properties['com.sun.management.jmxremote.ssl'] ?= 'true'
        service.deps.yarn_nm.options.opts.java_properties['com.sun.management.jmxremote.ssl.need.client.auth'] ?= 'false'
        options.jmx_ssl_config['javax.net.ssl.keyStore'] ?= "#{service.deps.yarn_nm.options.conf_dir}/keystore"
        throw Error 'Missing Datanode Keystore Password' unless options.ssl?.keystore?.password
        options.jmx_ssl_config['javax.net.ssl.keyStorePassword'] ?= options.ssl.keystore.password
        #jmx_exporter client truststore
        options.opts.java_properties['javax.net.ssl.trustStore'] ?= "#{service.deps.yarn_nm.options.conf_dir}/truststore"
        throw Error 'Missing Datanode Truststore Password' unless options.ssl?.truststore?.password
        options.opts.java_properties['javax.net.ssl.trustStorePassword'] ?=  options.ssl.truststore.password
      else
        options.jmx_config['com.sun.management.jmxremote.ssl'] ?= 'false'

## Enable JMX Authentication

      options.authenticate ?= 'false'
      if options.authenticate
        options.username ?= 'monitorRole'# be careful if changing , should configure access file
        options.jmx_auth_file ?=  '/etc/security/jmxPasswords/yarn-nodemanager.password'
        options.jmx_config['com.sun.management.jmxremote.authenticate'] ?= 'true'
        throw Error 'Missing options.password' unless options.password
        options.jmx_config['com.sun.management.jmxremote.password.file'] ?= options.jmx_auth_file

## Configuration
configure JMX Exporter to scrape Zookeeper metrics. [this example][example] is taken from
[JMX Exporter][jmx_exporter] repository.

      # Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false
      options.port ?= 5560
      options.cluster_name ?= "ryba-env-metal"
      options.config ?= {}
      options.config['startDelaySeconds'] ?= 0
      options.config['ssl'] ?= false
      options.config['hostPort'] ?= "#{service.deps.yarn_nm.node.fqdn}:#{options.jmx_config['com.sun.management.jmxremote.port']}"
      options.config['username'] ?= options.username
      options.config['password'] ?= options.password
      options.config['lowercaseOutputName'] ?= true
      options.config['rules'] ?= []
      options.config['rules'].push 'pattern': '.*'

## Register Prometheus Scrapper
configure by default two new label, one cluster and the other service
Note: cluster name shoul not contain other character than ([a-zA-Z0-9\-\_]*)

      options.relabel_configs ?= [
          source_labels: ['job']
          regex: "([a-zA-Z0-9\\-\\_]*).([a-zA-Z0-9]*)"
          target_label: "cluster"
          replacement: "$1"
        ,
          source_labels: ['job']
          regex: "([a-zA-Z0-9\\-\\_]*).([a-zA-Z0-9]*)"
          target_label: "service"
          replacement: "$2"
        ,
          source_labels: ['__address__']
          regex: "([a-zA-Z0-9\\-\\_\\.]*):([a-zA-Z0-9]*)"
          target_label: "hostname"
          replacement: "$1"
        ]
      for srv in service.deps.prometheus_monitor
        srv.options.config ?= {}
        srv.options.config['scrape_configs'] ?= []
        scrape_config = null
        # iterate through configuration to find zookeeper's one
        # register current fqdn if not already existing
        for conf in srv.options.config['scrape_configs']
          scrape_config = conf if conf.job_name is "#{options.cluster_name}.nodemanager"
        exist = scrape_config?
        scrape_config ?=
          job_name: "#{options.cluster_name}.nodemanager"
          static_configs:
            [
              targets: []
            ]
          relabel_configs: options.relabel_configs
        for static_config in scrape_config.static_configs
          hostPort = "#{service.node.fqdn}:#{options.port}"
          static_config.targets ?= []
          static_config.targets.push hostPort unless static_config.targets.indexOf(hostPort) isnt -1
        srv.options.config['scrape_configs'].push scrape_config unless exist
## Wait

      options.wait ?= {}
      options.wait.jmx ?=
        host: service.node.fqdn
        port: options.port or '5560'

## Dependencies

    mixme = require 'mixme'

[example]:(https://github.com/prometheus/jmx_exporter/blob/master/example_configs/zookeeper.yaml)
[jmx_exporter]:(https://github.com/prometheus/jmx_exporter)
