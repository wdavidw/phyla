
# Titan Check

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'ryba/hbase/master/wait'
    module.exports.push require('./index').configure

## Check Configuration

TODO: use ctx.ssh.shell

Check the configuration file (current.properties)

    module.exports.push name: 'Titan # Check Shell', label_true: 'CHECKED', handler: (ctx, next) ->
      {shortname} = ctx.config
      {titan} = ctx.config.ryba
      cmd = "g = TitanFactory.open('titan-#{titan.config['storage.backend']}-#{titan.config['index.search.backend']}-test.properties')"
      ctx.execute
        cmd: mkcmd.test ctx, """
          cd #{titan.home}
          #{titan.install_dir}/current/bin/gremlin.sh 2>/dev/null <<< "#{cmd}" | grep '==>titangraph'
        """
      , next

## Module Dependencies

    mkcmd = require '../lib/mkcmd'