
# Logstash Install

    module.exports = header: 'Logstash Install', handler: (options) ->

## IPTables

| Service             | Port   | Proto | Info                   |
|---------------------|------- |-------|------------------------|
| Pipeline port       | custom | http  | hbase.master.port      |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @each options.pipelines, (opts) ->
        name = opts.key
        pipeline = opts.value
        @tools.iptables
          header: 'IPTables'
          if: options.iptables
          rules: [
            { chain: 'INPUT', jump: 'ACCEPT', dport: pipeline.port, protocol: 'tcp', state: 'NEW', comment: "Pipeline #{name}" }
          ]
          
## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Install

      @call header: 'Packages', ->
        @file.download
          source: options.source
          target: "/var/tmp/logstash-#{options.version}.rpm"
        @system.execute
          cmd: "yum localinstall -y --nogpgcheck /var/tmp/logstash-#{options.version}.rpm"
          unless_exec: "rpm -q --queryformat '%{VERSION}' logstash | grep '#{options.version}'"

## Config

      @call header: 'Configuration', ->
        @file.render
          header: 'logstash.yml'
          target: "#{options.conf_dir}/logstash.yml"
          source: "#{__dirname}/../resources/logstash.yml.j2"
          local: true
          context: options
          # uid: options.user.name
          # gid: options.hadoop_group.name
          mode: 0o644
          backup: true
          # eof: true
          
## Pipelines

      @call header: 'Pipelines', ->
        @each options.pipelines, (opts) ->
          name = opts.key
          pipeline = opts.value
          content = """
          input {
            #{ if pipeline.inputs.redis?
              """
              redis {
                  host => "#{pipeline.inputs.redis.host}"
                  port => "#{pipeline.inputs.redis.port}"
                  data_type => "list"
                  key => "#{pipeline.inputs.redis.key}"
                }
              """
            else ''}
            #{ if pipeline.inputs.filebeat?
              """
              beats { port => "#{pipeline.inputs.filebeat.port}" }
              """
            else ''}
          }
          filter {
            grok {
                match => { #{pipeline.match} }
            }
          }
          output {
            #{ if pipeline.outputs.es?
              """
              elasticsearch { hosts => #{pipeline.outputs.es.hosts} }
              """
              }
            #{ if pipeline.outputs.solr?
              """
              solr_http { solr_url => "#{pipeline.outputs.solr.host}" }
              """
              }
          }
          """
          @file
            target: "#{options.conf_dir}/conf.d/#{name}.conf"
            content: content
            backup: true

## Solr http plugin

      @call header: 'solr_http plugin install', ->        
        @file.download
          source: "#{__dirname}/../resources/logstash-offline-plugins-6.1.1.zip"
          target: "#{options.install_dir}/logstash/add_gems/logstash-offline-plugins-6.1.1.zip"
        @system.execute
          cmd: "#{options.install_dir}/logstash/bin/logstash-plugin install file://#{options.install_dir}/logstash/add_gems/logstash-offline-plugins-6.1.1.zip"
        @file
          header: 'Remove iso8601 timestamp conversion'
          target: "#{options.install_dir}/logstash/vendor/bundle/jruby/2.3.0/gems/logstash-output-solr_http-3.0.4/lib/logstash/outputs/solr_http.rb"
          write: [
            match: /.*document\[\"@timestamp\"\] = document\[\"@timestamp\"\]\.iso8601.*/
            replace: ""
          ]
