
# JMX Exporter Knox Install

    module.exports = header: 'JMX Exporter Knox Auth', handler: ({options}) ->

## Registry

      @registry.register ['jmx', 'password'], '@rybajs/storage/prometheus/actions/jmx_password'

## Layout

      @jmx.password
        title: 'DN JMX'
        username: options.username
        password: options.password
        target: options.jmx_auth_file
        uid: options.hdfs_user.name
        gid:  options.hdfs_group.name

      @file
        header: 'JMX Properties'
        target: options.jmx_config_file
        write: for k, v of options.jmx_config
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true
        uid: options.hdfs_user.name
        gid:  options.hdfs_group.name
        mode: 0o600

      @file
        header: 'JMX SSL Properties'
        target: options.jmx_ssl_file
        write: for k, v of options.jmx_ssl_config
          match: RegExp "#{k}=.*", 'm'
          replace: "#{k}=#{v}"
          append: true
        uid: options.hdfs_user.name
        gid:  options.hdfs_group.name
        mode: 0o600
