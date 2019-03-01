
# Grafana Datasource

Create a Grafana Datasource using [REST API](http://docs.grafana.org/http_api/data_source/)

* `password` (string)
  Ranger Administrator password.
* `url` (string)   
  Policy Manager External URL ("POLICY\_MGR\_URL").
* `username` (string)
  Ranger Administrator username.
* `dashboard` (object)   
  The dashboard configuration.
* `name` (string)   
  The unique name of the datasource.Mandatory.
* `datasource` (string)   
  The datasource type. graphite, prometheus.
* `datasource_url` (string)   
  The data source url. Mandatory.   
* `access` (string)   
  access type. proxy by default.
    
  
## Exemple

```js
nikita
.grafana_datasource({
  "username": 'ranger_username',
  "password": 'ranger_secret',
  "url": "http://ranger.policy.manager",
  "name":"test_datasource",
  "type":"graphite",
  "url":"http://mydatasource.com",
  "access":"proxy",
  "basicAuth":false
  }
}, function(err, status){
  console.log( err ? err.message : "Policy Created: " + status)
})
```

    module.exports = ({options}) ->
      throw Error 'Required Options: username' unless options.username?
      throw Error 'Required Options: password' unless options.password?
      throw Error 'Required Options: url' unless options.url?
      throw Error 'Required Options: name' unless options.name?
      throw Error 'Required Options: datasource_url' unless options.datasource_url?
      throw Error 'Required Options: datasource' unless options.datasource?
      options.access ?= 'proxy'
      options.basicAuth ?= false
      obj =
        name: options.name
        type: options.datasource
        url: options.datasource_url
        Access: options.access
        basicAuth: options.basicAuth
      options.slug ?= options.name.toLowerCase().split(' ').join('-')
      @system.execute
        cmd: """
        curl --fail -H "Content-Type: application/json" -k -X POST \
           -d '#{JSON.stringify obj}' \
          -u #{options.username}:#{options.password} \
          "#{options.url}/api/datasources"
        """
        unless_exec: """
          curl --fail -H "Content-Type: application/json" -k -X GET  \
            -u #{options.username}:#{options.password} \
            "#{options.url}/api/datasources/#{options.slug}"
          """
