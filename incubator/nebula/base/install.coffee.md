
# Open Nebula Front Install

Install Nebula front end on the specified hosts.
http://docs.opennebula.org/5.2/deployment/opennebula_installation/frontend_installation.html

    module.exports = header: 'Nebula Base Install', handler: (options) ->

## Identitites

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep oneadmin
oneadmin:x:9869:9869::/var/lib/one:/bin/bash
cat /etc/group | grep oneadmin
oneadmin:x:9869:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Add Nebula repositories

      @tools.repo
        if: options.repo.source?
        header: 'Repository'
        source: options.repo.source
        target: options.repo.target
        replace: options.repo.replace
        update: true
