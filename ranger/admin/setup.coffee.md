
# Ranger Admin Setup

    module.exports =  header: 'Ranger Admin Setup', handler: (options) ->

      protocol = if options.site['ranger.service.https.attrib.ssl.enabled'] is 'true' then 'https' else 'http'
      port = options.site["ranger.service.#{protocol}.port"]

## Web UI Admin Account
Modify admin account password. By default the login:pwd  is `admin:admin`.

      @call header: 'Ranger Admin Account', ->
        @connection.wait
          host: @config.host
          port: port
        @system.execute
          header: "Check admin password"
          cmd: """
          curl -H \"Content-Type: application/json\"  --fail -k -X GET \
            -u admin:#{options.admin.password} \"#{options.install['policymgr_external_url']}/service/users/1\"
          """
          code_skipped: 22
          shy: true
        @system.execute
          unless: -> @status -1
          header: "Change admin password"
          cmd: """
          curl -H \"Content-Type: application/json\" --fail -k -X POST -d '#{JSON.stringify oldPassword: options.current_password, updPassword: options.admin.password, loginId: 'admin'}'  \
            -u admin:#{options.current_password} \"#{options.install['policymgr_external_url']}/service/users/1/passwordchange\"
          """

## User Accounts
Deploying some user accounts. This middleware is here to serve
as an example of adding a user,and giving it some permission.
Requires `admin` user to have `ROLE_SYS_ADMIN`.
Method to check is user account already exit is not identical base on user source.
Indeed usersource to 1 means external user and so unknown password.

      @call header: 'Ranger Admin Manager Users Accounts', ->
        for name, user of options.users
          @system.execute
            if: user.userSource is 0
            cmd: """
            curl --fail -H "Content-Type: application/json"   -k -X POST \
              -d '#{JSON.stringify user}' -u admin:#{options.admin.password} \
              \"#{options.install['policymgr_external_url']}/service/xusers/secure/users\"
            """
            unless_exec: """
            curl --fail -H "Content-Type: application/json"   -k -X GET \
              -u #{name}:#{user.password} \
              \"#{options.install['policymgr_external_url']}/service/users/profile\"
            """
          @system.execute
            if: user.userSource is 1
            cmd: """
            curl --fail -H "Content-Type: application/json"   -k -X POST \
              -d '#{JSON.stringify user}' -u admin:#{options.admin.password} \
              \"#{options.install['policymgr_external_url']}/service/xusers/secure/users\"
            """
            unless_exec: """
            curl --fail -H "Content-Type: application/json"   -k -X GET \
              -u admin:#{options.admin.password} \
              \"#{options.install['policymgr_external_url']}/service/xusers/users/userName/#{name}\"
            """
