# Ranger Admin Wait

Wait for Ranger Admin Policy Manager to start.

    module.exports = header: 'Ranger Admin Wait', label_true: 'READY', handler: (options) ->
      [ranger_admin_ctx] = (@contexts 'ryba/ranger/admin')
      {ranger} = ranger_admin_ctx.config.ryba
      protocol = if ranger.admin.site['ranger.service.https.attrib.ssl.enabled'] is 'true' then 'https' else 'http'
      port = ranger.admin.site["ranger.service.#{protocol}.port"]
      @wait.execute
        cmd: """
        curl --fail -H "Content-Type: application/json" -k -X GET \
          -u admin:#{options.password} \
          "#{options.url}"
        """
        code_skipped: [1,7,22]
