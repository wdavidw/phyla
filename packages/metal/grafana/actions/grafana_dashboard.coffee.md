
# Grafana Dashboard

Create a Grafana Dashboard using [REST API](http://docs.grafana.org/http_api/dashboard/)
When creating a dashboard Grafana needs details. At least the title is needed.
If the title only is specified, an empty fashboard is created.
If the dashboard option is provided, ryba submit it directly as post data
If source option is provided, ryba renders the soure  as template.
Administrators can use directly the `dashb` object which will override title options.
Administrators can also pass `source` options if the config should be read from a file
( for example importing a json from an old grafana instance)

Grafana sanitizes the dashboard names to lowercase and replace space with -
For example "My new dashbard" will become my-new-dashboard

* `password` (string)
  Ranger Administrator password.
* `url` (string)   
  Policy Manager External URL ("POLICY\_MGR\_URL").
* `username` (string)
  Ranger Administrator username.
* `dashboard` (object)   
  The dashboard configuration.
* `name` (string)   
  The title of the dashboard.(Not used if config or source).
* `source` (string)   
  The dashboard configuration file.
* `local` (boolean)   
  If the source is local. Mandatory if source options.* `local` (boolean)   
* `rows` (Array)   
  List of rows containing panels.
    
  
## Exemple

```js
nikita
.grafana_dashboard({
  "username": 'ranger_username',
  "password": 'ranger_secret',
  "url": "http://ranger.policy.manager",
  "title": "HDFS Datanodes"
  }
}, function(err, status){
  console.log( err ? err.message : "Policy Created: " + status)
})
```

    module.exports = ({options}) ->
      throw Error 'Required Options: username' unless options.username?
      throw Error 'Required Options: password' unless options.password?
      throw Error 'Required Options: url' unless options.url?
      throw Error 'Required Options: title' unless options.title?
      throw Error 'Required Options: datasource' unless options.datasource?
      throw Error 'Required Options: local when source is used' if options.source and !options.local
      options.slug ?= options.title.toLowerCase().replace(/[\s]*/, '-')
      options.merge = false
      options.rows ?= []
      options.tags ?= []
      options.dashboard ?=
        dashboard:
          title: options.title
          id: null
          tags: options.tags
          timezone: 'browser'
          rows: options.rows
          schemaVersion: 6
          version: 0
        overwrite: false
      options.dashboard.dashboard.title = options.title if options.dashboard?
      data_options = " -d @/tmp/dashboard.json "
      @call
        unless_exec: """
          curl --fail -H "Content-Type: application/json" -k -X GET  \
            -u #{options.username}:#{options.password} \
            "#{options.url}/api/dashboards/db/#{options.slug}"
          """
      , ->
      #read file from source, for title merge
      # uncomment if add merge 
      # @call
      #   shy: true
      #   if: options.source?
      # , (_, cb) ->
      #   fs.readFile options.source, 'UTF-8', (err, data) ->
      #     throw err if err
      #     dashboard = JSON.parse data.toString()
      #     if options.merge
      #       options.dashboard = mixme options.dashboard, dashboard, title: options.title
      #     else
      #       options.dashboard = dashboard
      #     cb()
        @file
          target: '/tmp/dashboard.json'
          if: options.source?
          source: options.source
          local: options.local
          context: options
          shy: true
        @file
          target: '/tmp/dashboard.json'
          unless: options.source?
          content: JSON.stringify options.dashboard
          shy: true
        @system.execute
          cmd: """
          curl --fail -H "Content-Type: application/json" -k -X POST \
             #{data_options} \
            -u #{options.username}:#{options.password} \
            "#{options.url}/api/dashboards/db"
          """
        @system.remove
          target: '/tmp/dashboard.json'
          shy: true
        



## Dependencies

    fs = require 'fs'
    mixme = require 'mixme'
