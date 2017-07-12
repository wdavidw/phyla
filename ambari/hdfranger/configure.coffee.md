
# Ranger with Ambari Configure

    module.exports = ->
      ssl_ctxs = @contexts 'masson/core/ssl'
      {ssl} = @config
      options = @config.ambari_hdfranger ?= {}

## Environment

      options.conf_dir ?= '/etc/ranger/conf'

## User and Groups

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'ranger'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'ranger'
      options.user.gid = options.group.name
      options.user.system ?= true
      options.user.comment ?= 'Ranger User'
      options.user.home ?= '/var/lib/ranger'

## Ranger

https://community.hortonworks.com/articles/81184/understanding-the-initial-admin-identity-access-po.html

      options.ssl ?= {}
      options.ssl.enabled ?= false
      options.ssl.certs = {}
      options.ssl.truststore ?= {}
      options.ssl.keystore ?= {}
      if options.ssl
        options.ssl.cert = @config.ssl.cert
        options.ssl.key = @config.ssl.key
        options.ssl.cacert = @config.ssl.cacert
        for ssl_ctx in ssl_ctxs
          options.ssl.certs[ssl_ctx.config.shortname] ?= {}
          options.ssl.certs[ssl_ctx.config.shortname] = ssl_ctx.config.ssl.cert
        throw Error 'Required Property: truststore.password' unless options.ssl.truststore.password
        options.ssl.truststore.caname ?= 'hadoop_root_ca'
        options.ssl.truststore.type ?= 'jks'
        options.ssl.truststore.target ?= "#{options.conf_dir}/truststore.jks"
        throw Error "Invalid Truststore Type: #{truststore.type}" unless options.ssl.truststore.type in ['jks', 'jceks', 'pkcs12']
        options.ssl.keystore.target ?= "#{options.conf_dir}/keystore.jks"
        throw Error 'Required Property: keystore.password' unless options.ssl.keystore.password
        throw Error 'Required Property: keystore.keypass' unless options.ssl.keystore.keypass
