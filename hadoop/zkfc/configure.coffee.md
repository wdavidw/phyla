
# Hadoop ZKFC Configure

ZKFC doesnt have any required configuration. By default, it uses the SASL
mechanism to connect to zookeeper using kerberos.

Optional, activate digest type access to zookeeper to manage the zkfc znode:

```json
{ 
  "digest": {
    "name": "zkfc",
    "password": "hdfs123"
  }
}
```

    module.exports = (service) ->
      options = service.options

## Identities

      options.hadoop_group = merge {}, service.deps.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.deps.hadoop_core.options.hdfs.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.hdfs.user, options.user

## Environment

      # Layout
      options.pid_dir ?= service.deps.hadoop_core.options.hdfs.pid_dir
      options.log_dir ?= service.deps.hadoop_core.options.hdfs.log_dir
      options.conf_dir ?= '/etc/hadoop-hdfs-zkfc/conf'
      options.nn_conf_dir ?= service.deps.hdfs_nn_local.options.conf_dir
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.hadoop_heap ?= service.deps.hadoop_core.options.hadoop_heap
      options.hadoop_opts ?= service.deps.hadoop_core.options.hadoop_opts
      options.opts ?= ''
      # Misc
      options.fqdn = service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.hdfs_krb5_user = service.deps.hadoop_core.options.hdfs.krb5_user
      options.clean_logs ?= false

## Configuration

      options.core_site ?= merge {}, service.deps.hadoop_core.options.core_site, options.core_site or {}
      options.core_site['ha.zookeeper.quorum'] ?= service.deps.zookeeper_server
      .filter (srv) -> srv.options.config['peerType'] is 'participant'
      .map (srv)-> "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"
      .join(',')
      # Validation
      options.principal ?= service.deps.hdfs_nn_local.options.hdfs_site['dfs.namenode.kerberos.principal']
      options.nn_principal ?= service.deps.hdfs_nn_local.options.hdfs_site['dfs.namenode.kerberos.principal']
      options.keytab ?= service.deps.hdfs_nn_local.options.hdfs_site['dfs.namenode.keytab.file']
      options.nn_keytab ?= service.deps.hdfs_nn_local.options.hdfs_site['dfs.namenode.keytab.file']
      options.jaas_file ?= "#{options.conf_dir}/zkfc.jaas"
      options.digest ?= {}
      options.digest.name ?= 'zkfc'
      options.digest.password ?= null
      # Environment
      if options.core_site['hadoop.security.authentication'] is 'kerberos'
        options.opts = "-Djava.security.auth.login.config=#{options.jaas_file} #{options.opts}"
      # Enrich "core-site.xml" with acl and auth
      options.core_site['ha.zookeeper.acl'] ?= "@#{options.conf_dir}/zk-acl.txt"
      options.core_site['ha.zookeeper.auth'] = "@#{options.conf_dir}/zk-auth.txt"
      # Enrich "hdfs-site.xml"
      options.hdfs_site ?= {}
      options.hdfs_site['dfs.ha.zkfc.port'] ?= '8019'

      for property in [
        'dfs.namenode.kerberos.principal'
        'dfs.namenode.keytab.file'
        # 'dfs.namenode.kerberos.internal.spnego.principal'
        # 'dfs.namenode.kerberos.https.principal'
        # 'dfs.web.authentication.kerberos.principal'
        'dfs.ha.automatic-failover.enabled'
        'dfs.nameservices'
        'dfs.internal.nameservices'
        'fs.permissions.umask-mode'
      ] then options.hdfs_site[property] ?= service.deps.hdfs_nn_local.options.hdfs_site[property]
      for property, value of service.deps.hdfs_nn_local.options.hdfs_site
        ok = false
        ok = true if /^dfs\.namenode\.\w+-address/.test property
        # ok = true if property.indexOf('dfs.client.failover.proxy.provider.') is 0
        ok = true if property.indexOf('dfs.ha.namenodes.') is 0
        continue unless ok
        options.hdfs_site[property] ?= value
      options.nn_hosts ?= service.deps.hdfs_nn.map( (srv) -> srv.node.fqdn ).join(',')

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.deps.krb5_client.options.admin[options.krb5.realm]

## HA

      options.dfs_nameservices ?= service.deps.hdfs_nn_local.options.hdfs_site['dfs.nameservices']
      options.automatic_failover ?= service.deps.hdfs_nn_local.options.hdfs_site['dfs.ha.automatic-failover.enabled'] is 'true'
      options.active_nn_host ?= service.deps.hdfs_nn_local.options.active_nn_host
      options.standby_nn_host ?= service.deps.hdfs_nn_local.options.standby_nn_host
      options.active_shortname ?= service.instances.filter( (instance) -> instance.node.fqdn is options.active_nn_host )[0].node.hostname
      options.standby_shortname ?= service.instances.filter( (instance) -> instance.node.fqdn is options.standby_nn_host )[0].node.hostname
      # options.active_shortname = service.deps.hdfs_nn_local.filter( (srv) -> srv.node.fqdn is srv.options.active_nn_host )[0].node.hostname
      # options.standby_shortname = service.deps.hdfs_nn_local.filter( (srv) -> srv.node.fqdn is srv.options.standby_nn_host )[0].node.hostname

### Fencing

To prevent split-brain scenario, in addition to the Journal Quorum Process for
write, sshfence allow ssh connection to the previous disfunctioning active
namenode from the new one to "shoot it in the head" (STONITH).

If the previous master machine is dead, ssh connection will fail, so another
fencing method should be configured to not block failover.

      options.hdfs_site['dfs.ha.fencing.methods'] ?= """
      sshfence(#{options.user.name})
      shell(/bin/true)
      """
      options.hdfs_site['dfs.ha.fencing.ssh.connect-timeout'] ?= '30000'
      options.hdfs_site['dfs.ha.fencing.ssh.private-key-files'] ?= "#{options.user.home}/.ssh/id_rsa"
      # TODO: keys must be local or remote, only local supported for the moment
      throw Error "Required Option: ssh_fencing.private_key" unless options.ssh_fencing.private_key
      throw Error "Required Option: ssh_fencing.public_key" unless options.ssh_fencing.public_key

## Wait

      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait_hdfs_nn = service.deps.hdfs_nn_local.options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
