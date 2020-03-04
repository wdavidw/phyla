
# Pip Install

    module.exports = header: 'Pip', handler: ({options}) ->

## Install pip

      @service
        header: "Install python2-pip package"
        name: "python2-pip"

      @system.execute
        header: "Upgrade pip"
        cmd: "pip install --upgrade pip"

### Install pip packages

      for pckg in options.packages
        @system.execute
          header: "Install #{pckg} pip"
          cmd: "pip install #{pckg}"

## Dependencies

    each = require 'each'