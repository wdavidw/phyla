
# Hadoop Yarn ResourceManager Check

Check the health of the ResourceManager(s).

    module.exports = header: 'YARN RM Check', handler: (options) ->

## Wait

Wait for the ResourceManager.

      @call once: true, 'ryba/hadoop/yarn_rm/wait', options.wait

## Check Health

Connect to the provided ResourceManager to check its health. This command
`yarn rmadmin -checkHealth {serviceId}` return 0 if the ResourceManager is
healthy, non-zero otherwise. This check only apply to High Availability
mode.

      @system.execute
        header: 'HA Health'
        if: options.yarn_site['yarn.resourcemanager.ha.enabled'] is 'true'
        cmd: mkcmd.hdfs @, "yarn --config #{options.conf_dir} rmadmin -checkHealth #{options.hostname}"
        retry: 3
        wait: 5000

# Dependencies

    mkcmd = require '../../lib/mkcmd'
