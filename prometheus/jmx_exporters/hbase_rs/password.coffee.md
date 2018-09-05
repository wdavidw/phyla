
# JMX Exporter RS Install

    module.exports = header: 'JMX Exporter Regionserver Auth', handler: ({options}) ->

## Registry

      @registry.register ['jmx', 'password'], 'ryba/prometheus/actions/jmx_password'

## Layout

      @jmx.password
        title: 'RS JMX'
        username: options.username
        password: options.password
        target: options.jmx_auth_file
        uid: options.hbase_user.name
        gid:  options.hbase_group.name

      @file
        header: 'JMX Properties'
        target: options.jmx_config_file
        write: for k, v of options.jmx_config
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true
        uid: options.hbase_user.name
        gid:  options.hbase_group.name
        mode: 0o600

      @file
        header: 'JMX SSL Properties'
        target: options.jmx_ssl_file
        write: for k, v of options.jmx_ssl_config
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true
        uid: options.hbase_user.name
        gid:  options.hbase_group.name
        mode: 0o600
