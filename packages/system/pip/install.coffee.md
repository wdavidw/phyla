
# Pip Install

    module.exports = header: 'Pip', handler: ({options}) ->

## Install pip

      @service
        header: "Install python3-pip package"
        name: "python3-pip"

      @system.execute
        header: "Upgrade pip"
        cmd: "pip3 install --upgrade pip"

### Install pip packages

      for pckg in options.packages
        @system.execute
          header: "Install #{pckg} pip"
          cmd: "pip3 install #{pckg}"

## Dependencies

    each = require 'each'