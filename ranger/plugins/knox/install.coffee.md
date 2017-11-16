
# Ranger Knox Plugin Install

    module.exports = header: 'Ranger Knox Plugin', handler: (options) ->
      version = null

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @registry.register 'ranger_service', 'ryba/ranger/actions/ranger_service'

## Wait

      @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin

## Packages

      @call header: 'Packages', ->
        @system.execute
          header: 'Setup Execution'
          shy:true
          cmd: """
          hdp-select versions | tail -1
          """
         , (err, executed,stdout, stderr) ->
            return  err if err or not executed
            version = stdout.trim() if executed
        @service
          name: "ranger-knox-plugin"

## Service Repository creation

Matchs step 1 in [Knox plugin configuration][plugin]. Instead of using the web ui
we execute this task using the rest api.

      @ranger_service
        header: 'Ranger Repository'
        username: options.ranger_admin.username
        password: options.ranger_admin.password
        url: options.install['POLICY_MGR_URL']
        service: options.service_repo

Note, by default, we're are using the same Ranger principal for every
plugin and the principal is created by the Ranger Admin service. Chances
are that a customer user will need specific ACLs but this hasn't been
tested.

      @krb5.addprinc options.krb5.admin,
        header: 'Plugin Principal'
        principal: "#{options.service_repo.configs.username}"
        password: options.service_repo.configs.password

## Audit Layout

The value present in "XAAUDIT.HDFS.DESTINATION_DIRECTORY" contains variables
such as "%app-type% and %time:yyyyMMdd%".

      @hdfs_mkdir
        header: 'HDFS Audit'
        if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
        target: "/#{options.user.name}/audit/#{options.service_repo.type}"
        mode: 0o0750
        parent:
          mode: 0o0711
          user: options.user.name
          group: options.group.name
        user: options.knox_user.name
        group: options.knox_group.name
        krb5_user: options.hdfs_krb5_user
      @system.mkdir
        target: options.install['XAAUDIT.HDFS.FILE_SPOOL_DIR']
        uid: options.knox_user.name
        gid: options.hadoop_group.name
        mode: 0o0750
        if: options.install['XAAUDIT.HDFS.IS_ENABLED'] is 'true'
      @system.mkdir
        header: 'Solr Spool Dir'
        if: options.install['XAAUDIT.SOLR.IS_ENABLED'] is 'true'
        target: options.install['XAAUDIT.SOLR.FILE_SPOOL_DIR']
        uid: options.knox_user.name
        gid: options.hadoop_group.name
        mode: 0o0750

## Properties

      @call -> @file
        header: 'Properties'
        if: -> version?
        source: "#{__dirname}/../../resources/plugin-install.properties"
        target: "/usr/hdp/#{version}/ranger-knox-plugin/install.properties"
        local: true
        eof: true
        backup: true
        write: for k, v of options.install
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true

## Plugin Scripts 

      @call ->
        @file
          header: 'Script Fix'
          target: "/usr/hdp/#{version}/ranger-knox-plugin/enable-knox-plugin.sh"
          write:[
              match: RegExp "^HCOMPONENT_CONF_DIR=.*$", 'mg'
              replace: "HCOMPONENT_CONF_DIR=#{options.conf_dir}"
          ]
          backup: true
          mode: 0o750
        @system.execute
          header: 'Script Execution'
          cmd: """
          export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec
          if /usr/hdp/#{version}/ranger-knox-plugin/enable-knox-plugin.sh ;
          then exit 0 ;
          else exit 1 ;
          fi;
          """
        @system.execute
          header: 'fix topologies perms'
          cmd: "chown -R #{options.knox_user.name}:#{options.knox_user.name} /usr/hdp/current/knox-server/data/security/keystores/*"
        @system.copy
          source: '/etc/hadoop/conf/core-site.xml'
          target: "#{options.conf_dir}/core-site.xml"
        @system.copy
          source: '/etc/hadoop/conf/hdfs-site.xml'
          target: "#{options.conf_dir}/hdfs-site.xml"

## Dependencies

    quote = require 'regexp-quote'
    path = require 'path'
    mkcmd = require '../../../lib/mkcmd'

[plugin]: https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_knox_plugin
