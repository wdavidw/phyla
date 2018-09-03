

# Capacity Scheduler

The [CapacityScheduler][capacity], a pluggable scheduler for Hadoop which allows for
multiple-tenants to securely share a large cluster such that their applications
are allocated resources in a timely manner under constraints of allocated
capacities

Note about the property "yarn.scheduler.capacity.resource-calculator": The
default i.e. "org.apache.hadoop.yarn.util.resource.DefaultResourseCalculator"
only uses Memory while DominantResourceCalculator uses Dominant-resource to
compare multi-dimensional resources such as Memory, CPU etc. A Java
ResourceCalculator class name is expected.

    module.exports = header: 'YARN RM Sheduler', handler: ({options}) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

## Write Configuration

      @hconfigure
        header: 'Capacity Scheduler'
        if: options.yarn_site['yarn.resourcemanager.scheduler.class'] is 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler'
        target: "#{options.conf_dir}/capacity-scheduler.xml"
        source: "#{__dirname}/../../resources/core_hadoop/capacity-scheduler.xml"
        local: true
        properties: options.capacity_scheduler
        merge: false
        backup: true

## Reload

      @system.execute
        header: 'Reload'
        if: -> @status -1
        cmd: mkcmd.hdfs options.hdfs_krb5_user, "service hadoop-yarn-resourcemanager status && yarn --config #{options.conf_dir} rmadmin -refreshQueues || exit 0"


## Dependencies

    mkcmd = require '../../lib/mkcmd'
