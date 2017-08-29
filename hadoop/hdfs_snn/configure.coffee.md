
# Hadoop HDFS SecondaryNameNode 

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/hadoop/hdfs_jn', ['ryba', 'hdfs', 'jn'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hadoop_core: key: ['ryba']
      options = @config.ryba.hdfs.snn = service.options

## Environment

      # Layout
      options.pid_dir ?= service.use.hadoop_core.options.hdfs.pid_dir
      options.log_dir ?= service.use.hadoop_core.options.hdfs.log_dir
      options.conf_dir ?= '/etc/hadoop-hdfs-journalnode/conf'
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      # Misc
      options.clean_logs ?= false

## Identities

      options.hadoop_group = merge {}, service.use.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.use.hadoop_core.options.hdfs.group, options.group
      options.user = merge {}, service.use.hadoop_core.options.hdfs.user, options.user

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      # Admin Information
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]

## Configuration

      options.hdfs_site['dfs.http.policy'] ?= 'HTTPS_ONLY' # HTTP_ONLY or HTTPS_ONLY or HTTP_AND_HTTPS
      # Store the temporary images to merge
      options.hdfs_site['dfs.namenode.checkpoint.dir'] ?= ['file:///var/hdfs/checkpoint']
      options.hdfs_site['dfs.namenode.checkpoint.dir'] = options.hdfs_site['dfs.namenode.checkpoint.dir'].join ',' if Array.isArray options.hdfs_site['dfs.namenode.checkpoint.dir']
      options.hdfs_site['dfs.namenode.checkpoint.edits.dir'] ?= '${dfs.namenode.checkpoint.dir}' # HDP invalid default value
      # Network
      options.hdfs_site['dfs.namenode.secondary.http-address'] ?= "#{service.node.fqdn}:50090"
      # Kerberos principal name for the secondary NameNode.
      options.hdfs_site['dfs.secondary.namenode.kerberos.principal'] ?= "nn/_HOST@#{options.krb5.realm}"
      # Combined keytab file containing the NameNode service and host principals.
      options.hdfs_site['dfs.secondary.namenode.keytab.file'] ?= '/etc/security/keytabs/nn.service.keytab'
      # Address of secondary namenode web server
      options.hdfs_site['dfs.secondary.http.address'] ?= "#{service.node.fqdn}:50090"
      # The https port where secondary-namenode binds
      options.hdfs_site['dfs.secondary.https.port'] ?= '50490' # todo, this has nothing to do here
      options.hdfs_site['dfs.namenode.secondary.http-address'] ?= "#{service.node.fqdn}:50090"
      options.hdfs_site['dfs.namenode.secondary.https-address'] ?= "#{service.node.fqdn}:50490"
      options.hdfs_site['dfs.secondary.namenode.kerberos.internal.spnego.principal'] ?= "HTTP/_HOST@#{options.krb5.realm}"
      options.hdfs_site['dfs.secondary.namenode.kerberos.https.principal'] = "HTTP/_HOST@#{options.krb5.realm}"

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
