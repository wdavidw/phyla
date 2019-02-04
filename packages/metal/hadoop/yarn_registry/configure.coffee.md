
# Apache YArn REgisty Configuration
configures the registry according following [YARN 3.1 documentation](https://hadoop.apache.org/docs/r3.1.0/hadoop-yarn/hadoop-yarn-site/registry/registry-configuration.html)


    module.exports = (service) ->
      options = service.options

## Identities

      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.deps.hadoop_core.options.yarn.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.yarn.user, options.user
      options.ats_user = service.deps.hadoop_core.options.ats.user

## Options

      # Java
      options.yarn_home ?= '/usr/hdp/current/hadoop-yarn-registrydns'
      options.java_home ?= service.deps.java.options.java_home
      options.heapsize ?= '1024m'
      options.newsize ?= '200m'
      # Misc
      options.fqdn = service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user

## System Options

      options.opts ?= {}
      options.opts.base ?= ''
      options.opts.java_properties ?= {}
      options.opts.jvm ?= {}
      options.opts.jvm['-Xms'] ?= options.heapsize
      options.opts.jvm['-Xmx'] ?= options.heapsize
      options.opts.jvm['-XX:NewSize='] ?= options.newsize #should be 1/8 of heapsize
      options.opts.jvm['-XX:MaxNewSize='] ?= options.newsize #should be 1/8 of heapsize

## Configuration

      options.conf_dir ?= '/etc/hadoop-yarn-registrydns/conf'
      options.pid_dir ?= '/var/run/hadoop/yarn'
      options.log_dir ?= '/var/log/hadoop/yarn'

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]
      options.krb5.principal ?= "registry/_HOST@#{options.krb5.realm}"
      options.krb5.keytab ?= "/etc/security/keytabs/registry.service.keytab"
      
      zookeeper_quorum = for srv in service.deps.zookeeper_server
        continue unless srv.options.config['peerType'] is 'participant'
        "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"
      

## Configuration

      options.yarn_site ?= {}
      options.yarn_site['hadoop.registry.rm.enabled'] ?= 'true'
      options.yarn_site['hadoop.registry.zk.quorum'] ?= zookeeper_quorum
      options.yarn_site['hadoop.registry.zk.root'] ?= '/yarn-registry'

## Domain configuration
Follow [domain configuration](http://hadoop.apache.org/docs/r3.1.0/hadoop-yarn/hadoop-yarn-site/yarn-service/RegistryDNS.html).
You can even use yarn DNS a a dns for network resolution.
      
      options.yarn_site['hadoop.registry.dns.enabled ']	?= 'true'
      throw Error "yarn registry domain name  is not defined" unless options.yarn_site['hadoop.registry.dns.domain-name']?
      options.yarn_site['hadoop.registry.dns.bind-address'] ?= '0.0.0.0'
      options.yarn_site['hadoop.registry.dns.bind-port'] ?= '5353'

## ACL
By default, when acl are enabled, ony super users have the right to read/write registry znodes

      options.yarn_site['hadoop.registry.secure'] ?= 'true'
      options.yarn_site['hadoop.registry.jaas.context'] ?= 'Client'
      options.yarn_site['hadoop.registry.system.acls'] ?= 'sasl:yarn@, sasl:mapred@, sasl:mapred@, sasl:hdfs@'
      options.yarn_site['hadoop.registry.kerberos.realm'] ?= ''#takes the realm used by the running process

## Timeouts

      options.yarn_site['hadoop.registry.zk.session.timeout.ms'] ?= '60000'
      options.yarn_site['hadoop.registry.zk.connection.timeout.ms'] ?= '15000'
      options.yarn_site['hadoop.registry.zk.retry.times'] ?= '5'
      options.yarn_site['hadoop.registry.zk.retry.interval.ms'] ?= '1000'
      options.yarn_site['hadoop.registry.zk.retry.ceiling.ms'] ?= '60000'
      ats_srvs = if service.deps.yarn_ts then service.deps.yarn_ts else service.deps.yarn_tr
      # for srv in [service.deps.yarn_rm..., service.deps.yarn_ts..., service.deps.yarn_nm..., service.deps.yarn_client...]
      for srv in [service.deps.yarn_rm..., ats_srvs...]
        srv.options.yarn_site ?= {}
        for k, v of options.yarn_site
          srv.options.yarn_site[k] ?= v

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
