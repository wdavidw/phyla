
# OpenTSDB Start

    module.exports = header: 'OpenTSDB Start', handler: (options) ->
      {opentsdb, realm} = @config.ryba
      @system.execute
        cmd: "su -l #{opentsdb.user.name} -c \"kinit #{opentsdb.user.name}/#{options.fqdn}@#{realm} -k -t /etc/security/keytabs/opentsdb.service.keytab\""
        shy: true
      @service.start name: 'opentsdb'
