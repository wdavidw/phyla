
# Ranger HDFS Plugin Install

    module.exports = header: 'Ranger HDFS Plugin install', handler: (options) ->

## HDFS Dependencies

      @call 'ryba/ranger/admin/wait', once: true, options.wait_ranger_admin

## HDFS Service Repository creation

Matchs step 1 in [hdfs plugin configuration][hdfs-plugin]. Instead of using the web ui
we execute this task using the rest api.

      @system.execute
        header: 'Ranger HDFS Repository'
        if: options.repo_create
        unless_exec: """
        curl --fail -H "Content-Type: application/json" -k -X GET  \
          -u admin:#{options.admin_password} \"#{options.install['POLICY_MGR_URL']}/service/public/v2/api/service/name/#{options.install['REPOSITORY_NAME']}\"
        """
        cmd: """
        curl --fail -H "Content-Type: application/json" -k -X POST -d '#{JSON.stringify options.service_repo}' \
          -u admin:#{options.admin_password} \"#{options.install['POLICY_MGR_URL']}/service/public/v2/api/service/\"
        """

      # See [#96](https://github.com/ryba-io/ryba/issues/95): Ranger HDFS: should we use a dedicated principal
      @krb5.addprinc options.krb5.admin,
        # if: options.plugins.principal
        header: 'Ranger HDFS Principal'
        principal: "#{options.service_repo.configs.principal}@#{options.krb5.realm}"
        password: options.service_repo.configs.password

[hdfs-plugin]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/installing_ranger_plugins.html#installing_ranger_hdfs_plugin)
[hdfs-plugin-source]: https://github.com/apache/incubator-ranger/blob/ranger-0.6/agents-audit/src/main/java/org/apache/ranger/audit/utils/InMemoryJAASConfiguration.java
