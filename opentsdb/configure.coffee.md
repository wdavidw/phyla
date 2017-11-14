
## OpenTSDB Configuration

Options:

*   `user` (object|string)   
    The Unix OpenTSDB login name or a user object (see Nikita User documentation).   
*   `group` (object|string)   
    The Unix OpenTSDB group name or a group object (see Nikita Group documentation).   

Example:

```json
    "opentsdb": {
      "user": {
        "name": "opentsdb", "system": true, "gid": "opentsdb",
        "comment": "OpenTSDB User", "home": "/usr/share/opentsdb"
      },
      "group": {
        "name": "Opentsdb", "system": true
      }
    }
```

    module.exports = (service) ->
      rs_ctxs = @contexts 'ryba/hbase/regionserver'
      radmin_ctxs = @contexts 'ryba/ranger/admin'
      throw Error 'No HBase regionservers configured' unless service.deps.hbase_regionserver.length > 0
      {hbase} = rs_ctxs[0].config.ryba

      {options} = service

## Identities

      # Groups
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'opentsdb'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'opentsdb'
      options.user.system ?= true
      options.user.comment ?= 'OpenTSDB User'
      options.user.home = '/usr/share/opentsdb'
      options.user.gid = options.group.name
      options.user.limits ?= {}
      options.user.limits.nofile ?= 65535
      options.user.limits.nproc ?= true

## Package

      options.version ?= '2.3.0'
      options.source ?= "https://github.com/OpenTSDB/opentsdb/releases/download/v#{options.version}/opentsdb-#{options.version}.rpm"

## Configuration

      options.hbase ?= {}
      options.hbase.default_namespace ?= "opentsdb"
      options.hbase.bloomfilter ?= 'ROW'
      options.hbase.compression ?= 'SNAPPY'
      throw Error "Invalid hbase.bloomfilter '#{options.hbase.bloomfilter}' (NONE|ROW|ROWCOL)" unless options.hbase.bloomfilter in ['NONE', 'ROW', 'ROWCOL']
      throw Error "Invalid hbase.compression '#{options.hbase.compression}' (NONE|LZO|GZIP|SNAPPY)" unless options.hbase.compression in ['NONE', 'LZO', 'GZIP', 'SNAPPY']
      # Config
      options.config ?= {}
      options.config['tsd.core.auto_create_metrics'] ?= 'true'
      options.config['tsd.http.staticroot'] ?= "#{options.user.home}/static/"
      options.config['tsd.http.cachedir'] ?= '/tmp/opentsdb'
      options.config['tsd.core.plugin_path'] ?= "#{options.user.home}/plugins"
      options.config['tsd.core.meta.enable_realtime_ts'] ?= 'true'
      options.config['tsd.http.request.cors_domains'] ?= '*'
      options.config['tsd.network.port'] ?= 4242
      # Zookeeper
      # Get ZooKeeper Quorum
      options.config['tsd.storage.hbase.zk_quorum'] ?= (
        for srv in service.deps.zookeeper_server
          continue unless srv.options.config['peerType'] is 'participant'
          "#{srv.node.fqdn}:#{srv.options.config['clientPort']}"
      ).join ','
      options.config['tsd.storage.hbase.zk_basedir'] ?= hbase.rs.site['zookeeper.znode.parent']
      options.config['tsd.storage.fix_duplicates'] ?= 'true'
      options.config['tsd.storage.repair_appends'] ?= 'true'
      ns = (table) -> if options.hbase.default_namespace? then "#{options.hbase.default_namespace}:#{table}" else table
      options.config['tsd.storage.hbase.data_table'] ?= ns 'tsdb'
      options.config['tsd.storage.hbase.uid_table'] ?= ns 'tsdb-uid'
      options.config['tsd.storage.hbase.tree_table'] ?= ns 'tsdb-tree'
      options.config['tsd.storage.hbase.meta_table'] ?= ns 'tsdb-meta'
      options.config['tsd.query.allow_simultaneous_duplicates'] ?= 'true'
      options.config['hbase.security.authentication'] ?= hbase.rs.site['hbase.security.authentication']
      if options.config['hbase.security.authentication'] is 'kerberos'
        options.config['hbase.security.auth.enable'] ?= 'true' 
        options.config['hbase.kerberos.regionserver.principal'] ?= hbase.rs.site['hbase.regionserver.kerberos.principal']
        options.config['java.security.auth.login.config'] ?= '/etc/opentsdb/opentsdb.jaas'
        options.config['hbase.sasl.clientconfig'] ?= 'Client'
      # Env
      options.env ?= {}
      options.env['java.security.auth.login.config'] ?= options.config['java.security.auth.login.config']
      # Opts
      options.java_opts ?= ''

## Ranger Admin properties

      options.install['POLICY_MGR_URL'] ?= service.deps.ranger_admin.options.install['policymgr_external_url']
      options.install['REPOSITORY_NAME'] ?= 'hadoop-ryba-hbase'

## Ranger Plugin User

Create the opentsdb user if ranger hbase plugin is enabled.

      if service.deps.ranger_plugin_hbase
        options.plugin_user = merge
          'name': options.user.name
          'firstName': ''
          'lastName': ''
          'emailAddress': ''
          'password': null
          'userSource': 1
          'userRoleList': ['ROLE_USER']
          'groups': []
          'status': 1
        , options.plugin_user
        throw Error 'Required Option: plugin_user.password' unless options.plugin_user.password
