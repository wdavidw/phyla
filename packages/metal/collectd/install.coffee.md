
# Collectd Install
Install Collectd using epel packages. Collectd comes out of the box just need to install
and you are ready to run.

    module.exports = header: 'Collectd Install', handler: ({options}) ->

## Packages

      @service.install 'collectd'

## Plugins
Enable and write plugin config.
Enabling tell collectd to load the plugin at startup.
Writing plugin config tells collectd to use the enabled plugin with given parameters.

      @call header: 'Enable Plugins' , ->
        for k, v of options.plugins
          options.loads.push  v.type if options.loads.indexOf(v.type) is -1
        @file
          target: "#{options.conf_dir}/load-plugin.conf"
          content: options.loads.map( (type) ->
            "LoadPlugin #{type}").join("\n")
          local: true
        
      @call header: 'Write Plugins', ->
        {conf_dir} = options
        @each options.plugins, ({options}, cb) ->
          {key, value} = options
          switch value.type
            when 'network'
              @file.render
                source: "#{__dirname}/resources/plugin-network.conf.j2"
                target: "#{conf_dir}/#{key}.conf"
                context: value
                local: true
            when 'write_http'
              @file.render
                source: "#{__dirname}/resources/plugin-http.conf.j2"
                target: "#{conf_dir}/#{key}.conf"
                context: value
                local: true
            when 'df'
              @file.render
                source: "#{__dirname}/resources/plugin-df.conf.j2"
                target: "#{conf_dir}/#{key}.conf"
                context: value
                local: true
            when 'disk'
              @file.render
                source: "#{__dirname}/resources/plugin-disk.conf.j2"
                target: "#{conf_dir}/#{key}.conf"
                context: value
                local: true
          @next cb
      
