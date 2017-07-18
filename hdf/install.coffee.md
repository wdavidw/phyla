
# HDF Repository Install

    module.exports = header: 'HDF Install', handler: (options) ->
      options = @config.ryba.hdf

## Repository

      @tools.repo
        if: options.source?
        header: 'Repository'
        source: options.source
        target: options.target
        replace: options.replace
        update: true

## HDP - HDF Cohabitation

hdf-select package conflicts with hdp-select package (both provide /usr/bin/conf-select)
So we must manually force install of hdf-select outside of yum to handle it

      @call header: 'HDP/HDF Cohabitation', ->
        @system.execute
          unless_exec: 'yum list installed hdf-select'
          cmd: """
          yumdownloader --destdir=/tmp hdf-select
          rpm -i --replacefiles /tmp/hdf-select*.rpm
          rm -f /tmp/hdf-select*.rpm
          """
