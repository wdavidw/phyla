
# nscd Install

    module.exports = header: 'nscd', handler: ({options}) ->

## Configuration

      @file.ini
        header: 'Configuration'
        target: '/etc/nscd.conf'
        content: options.properties
        separator: '\t'
        backup: true

## Service

      @service
        header: 'Service'
        name: 'nscd'
        startup: true
        state: 'started'