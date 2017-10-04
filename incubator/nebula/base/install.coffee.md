
# OpenNebula Front Install

Install Nebula front end on the specified hosts.
http://docs.opennebula.org/5.2/deployment/opennebula_installation/frontend_installation.html

    module.exports = header: 'OpenNebula Base Install', handler: (options) ->

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

## Set private and public key for oneadmin

      # @call if: options.private_key_path, (_, callback) ->
      #   ssh = if options.local then null else options.ssh
      #   console.log !!ssh, options.private_key_path
      #   fs.readFile ssh, options.private_key_path, 'ascii', (err, data) ->
      #     options.private_key = data unless err
      #     callback err
      # @call if: options.public_key_path, (_, callback) ->
      #   ssh = if options.local then null else options.ssh
      #   fs.readFile ssh, options.public_key_path, 'ascii', (err, data) ->
      #     options.public_key = data unless err
      #     callback err
      @call header: 'Set keys', ->
        @file
          header: "private"
          target: "#{options.user.home}/.ssh/id_rsa"
          mode: 0o0600
          eof: true
        , options.private_key
        @file
          header: "public"
          target: "#{options.user.home}/.ssh/id_rsa.pub"
          mode: 0o0600
          eof: true
        , options.public_key
