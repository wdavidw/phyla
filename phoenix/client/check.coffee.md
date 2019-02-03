
# Phoenix Check

CSV data can be bulk loaded with built in utility named "psql.py". A shell is
available with the utility named "sqlline.py"

## Check Import and Select

Phoenix requires "RWXCA" permissions on the HBase table. Permission "execute" is
required for coprocessor execution and permission "admin" is required to grant
new permission to additionnal users.

Phoenix table are automatically converted to uppercase.

Refer to the [sqlline] documentation for a complete list of supported command
instructions.

    module.exports = header: 'Phoenix Client Check', handler: ({options}) ->
      zk_path = "#{options.site['hbase.zookeeper.quorum']}"
      zk_path += ":#{options.site['hbase.zookeeper.property.clientPort']}"
      zk_path += "#{options.site['zookeeper.znode.parent']}"

## Wait

      @call once: true, 'ryba/hbase/master/wait', options.wait_hbase_master
      @call once: true, 'ryba/hbase/regionserver/wait', options.wait_hbase_regionserver

## Check SQL Query

      table = "ryba_check_phoenix_#{options.hostname}".toUpperCase()
      @system.execute
        cmd: mkcmd.hbase options.admin, """
        export HBASE_CONF_DIR=#{options.hbase_conf_dir}
        hdfs dfs -rm -skipTrash check-#{options.hostname}-phoenix
        # Drop table if it exists
        # if hbase shell 2>/dev/null <<< "list" | grep '#{table}'; then echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null; fi
        echo "disable '#{table}'; drop '#{table}'" | hbase shell 2>/dev/null
        # Create table with dummy column family and grant access to ryba
        echo "create '#{table}', 'cf1'; grant 'ryba', 'RWXCA', '#{table}'" | hbase shell 2>/dev/null;
        """
        unless_exec: unless options.force_check then mkcmd.test options.test_krb5_user, "hdfs dfs -test -f check-#{options.hostname}-phoenix"
      @file
        target: "#{options.test.user.home}/check_phoenix/create.sql"
        uid: options.test.user.name
        gid: options.test.user.gid
        content: """
        CREATE TABLE IF NOT EXISTS #{table} (
          HOST CHAR(2) NOT NULL,
          DOMAIN VARCHAR NOT NULL,
          FEATURE VARCHAR NOT NULL,
          DATE DATE NOT NULL,
          USAGE.CORE BIGINT,
          USAGE.DB BIGINT,
          STATS.ACTIVE_VISITOR INTEGER
          CONSTRAINT PK PRIMARY KEY (HOST, DOMAIN, FEATURE, DATE)
        );
        """
      @file
        target: "#{options.test.user.home}/check_phoenix/select.sql"
        uid: options.test.user.name
        gid: options.test.user.group
        content: """
        SELECT DOMAIN, AVG(CORE) Average_CPU_Usage, AVG(DB) Average_DB_Usage 
        FROM #{table} 
        GROUP BY DOMAIN 
        ORDER BY DOMAIN DESC;
        """
      @system.execute
        cmd: mkcmd.test options.test_krb5_user, """
        export HBASE_CONF_DIR=#{options.hbase_conf_dir}
        cd /usr/hdp/current/phoenix-client/bin
        ./psql.py -t #{table} #{zk_path} \
          #{options.test.user.home}/check_phoenix/create.sql \
          ../doc/examples/WEB_STAT.csv \
        >/dev/null # 2>&1
        """
        retry: 5
        interval: 10000
      @wait.execute
        cmd: mkcmd.hbase options.admin, """
        export HBASE_CONF_DIR=#{options.hbase_conf_dir}
        hbase shell 2>/dev/null <<< "list" | grep '#{table}'
        """
      @system.execute
        cmd: mkcmd.test options.test_krb5_user, """
        export HBASE_CONF_DIR=#{options.hbase_conf_dir}
        cd /usr/hdp/current/phoenix-client/bin
        ./sqlline.py #{zk_path} \
          #{options.test.user.home}/check_phoenix/select.sql
        hdfs dfs -touchz check-#{options.hostname}-phoenix
        """
        retry: 5
        interval: 10000
        trap: true
      , (err, check, data) ->
        throw err if err
        throw Error "Invalid output" if check and data.trim().match(/\|(.*)\|(.*)\|(.*)\|/g).length isnt 4

## Dependencies

    mkcmd = require '../../lib/mkcmd'
    string = require '@nikitajs/core/lib/misc/string'

[sqlline]: http://sqlline.sourceforge.net/#commands
