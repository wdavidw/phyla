
# Files View Install
Instantiate a Files view. For now it does only create a single instance of the file view for current cluster.
It uses the Apache Ambari REST Api.

    module.exports =  header: 'Ambari Views', handler: (options)->
        url = ''
        protocol = if options.config['api.ssl'] is 'true' then 'https' else 'http'
        port = if protocol is 'https' then options.config['client.api.ssl.port'] else options.config['client.api.port']
        url = "#{protocol}://#{@config.host}:#{port}"

## Create the FILES View
        
        @system.execute
          header: 'FILES View'
          if: options.views.files.enabled
          cmd: """
            curl --fail --insecure --user admin:#{options.admin_password} -i -H 'X-Requested-By: ambari' -X POST \
            \"#{url}/api/v1/views/FILES/versions/#{options.views.files.version}/instances/RYBA_FILES_VIEW\" \
            --data '#{JSON.stringify ViewInstanceInfo:options.views.files}'
            """ 
          unless_exec: """
              curl --fail --insecure --user admin:#{options.admin_password} -i -H 'X-Requested-By: ambari' -X GET \
              \"#{url}/api/v1/views/FILES/versions/#{options.views.files.version}/instances/RYBA_FILES_VIEW\"
          """

## Create the HIVE View

        @system.execute
          header: 'HIVE View'
          if: options.views.hive.enabled
          cmd: """
            curl --fail --insecure --user admin:#{options.admin_password} -i -H 'X-Requested-By: ambari' -X POST \
            \"#{url}/api/v1/views/HIVE/versions/#{options.views.hive.version}/instances/RYBA_HIVE_VIEW\" \
            --data '#{JSON.stringify ViewInstanceInfo:options.views.hive.configuration}'
            """ 
          unless_exec: """
              curl --fail --insecure --user admin:#{options.admin_password} -i -H 'X-Requested-By: ambari' -X GET \
              \"#{url}/api/v1/views/HIVE/versions/#{options.views.hive.version}/instances/RYBA_HIVE_VIEW\"
          """
          #refers to hortonworks knowledge Base
          # when trying to instantiate a hive view. Some table might bemissing in ambari's database
          # its du to the fact that the page size for a row is to high (physical limit)
          # the table must be created with TEST attribute instead of varying character (2800)
          # @system.execute
          #   header: "Fix Ambari Database"
          #   unless_exec: db.cmd options.db, "select * from DS_JOBIMPL_1 limit 1"
          #   cmd: db.cmd options.db, """
                # CREATE TABLE DS_JOBIMPL_154 (
                #   ds_id TEXT NOT NULL,
                #   ds_applicationid TEXT,
                #   ds_conffile TEXT,
                #   ds_dagid TEXT,
                #   ds_dagname TEXT,
                #   ds_database TEXT,
                #   ds_datesubmitted bigint,
                #   ds_duration bigint,
                #   ds_forcedcontent TEXT,
                #   ds_globalsettings TEXT,
                #   ds_logfile TEXT,
                #   ds_owner TEXT,
                #   ds_queryfile TEXT,
                #   ds_queryid TEXT,
                #   ds_referrer TEXT,
                #   ds_sessiontag TEXT,
                #   ds_sqlstate TEXT,
                #   ds_status TEXT,
                #   ds_statusdir TEXT,
                #   ds_statusmessage TEXT,
                #   ds_title TEXT
                # );
          #   """

## Create the TEZ View  
        
        @system.execute
          header: 'TEZ View'
          if: options.views.tez.enabled
          cmd: """
            curl --fail --insecure --user admin:#{options.admin_password} -i -H 'X-Requested-By: ambari' -X POST \
            \"#{url}/api/v1/views/TEZ/versions/#{options.views.tez.version}/instances/RYBA_TEZ_VIEW\" \
            --data '#{JSON.stringify ViewInstanceInfo:options.views.tez.configuration}'
            """ 
          unless_exec: """
              curl --fail --insecure --user admin:#{options.admin_password} -i -H 'X-Requested-By: ambari' -X GET \
              \"#{url}/api/v1/views/TEZ/versions/#{options.views.tez.version}/instances/RYBA_TEZ_VIEW\"
          """

## Create the Workflow Manager (Oozie) View

        @system.execute
          header: 'Workflow Manager View'
          if: options.views.wfmanager.enabled
          cmd: """
            curl --fail --insecure --user admin:#{options.admin_password} -i -H 'X-Requested-By: ambari' -X POST \
            \"#{url}/api/v1/views/WORKFLOW_MANAGER/versions/#{options.views.wfmanager.version}/instances/RYBA_OOZIE_VIEW\" \
            --data '#{JSON.stringify ViewInstanceInfo:options.views.wfmanager.configuration}'
            """ 
          unless_exec: """
              curl --fail --insecure --user admin:#{options.admin_password} -i -H 'X-Requested-By: ambari' -X GET \
              \"#{url}/api/v1/views/WORKFLOW_MANAGER/versions/#{options.views.wfmanager.version}/instances/RYBA_OOZIE_VIEW\"
          """
