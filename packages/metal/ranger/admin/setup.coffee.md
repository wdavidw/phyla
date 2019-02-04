
# Ranger Admin Setup

    module.exports =  header: 'Ranger Admin Setup', handler: ({options}) ->

## Register

      @registry.register 'ranger_user', '@rybajs/metal/ranger/actions/ranger_user'


## Web UI Admin Account
Modify admin account password. By default the login:pwd  is `admin:admin`.

      @call header: 'Ranger Admin Account', ->
        protocol = if options.site['ranger.service.https.attrib.ssl.enabled'] is 'true' then 'https' else 'http'
        @connection.wait
          host: options.fqdn
          port: options.site["ranger.service.#{protocol}.port"]
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

      @ranger_user (
        header: "Account #{name}"
        username: options.admin.username
        password: options.admin.password
        url: options.install['policymgr_external_url']
        user: user
      ) for name, user of options.users
