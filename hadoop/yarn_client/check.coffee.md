
# Yarn Client Check

    module.exports = header: 'YARN Client Check', handler: ({options}) ->

## Wait

Wait for all YARN services to be started.

      # @call once: true, 'ryba/hadoop/yarn_ts/wait', options.wait_yarn_ts
      @call once: true, 'ryba/hadoop/yarn_rm/wait', options.wait_yarn_rm

## Check CLI

      @system.execute
        header: 'CLI'
        cmd: mkcmd.test options.test_krb5_user, 'yarn application -list'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
