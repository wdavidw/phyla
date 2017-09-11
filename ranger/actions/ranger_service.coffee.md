
# Ranger Service

* `password` (string)
  Ranger Administrator password.
* `url` (string)   
  Policy Manager External URL ("POLICY\_MGR\_URL").
* `username` (string)
  Ranger Administrator username.
* `service` (object)   
  Service to be created.
* `service.name` (string)   
  Name of the service, required.

## Exemple

```js
nikita
.ranger_service({
  "username": "ranger_username",
  "password": "ranger_secret",
  "url": "http://ranger.policy.manager",
  "service": {
    "name": options.install["REPOSITORY_NAME"],
    "description": "Hive Repo",
    "isEnabled": true,
    "type": "hive",
    "configs": {
      "username": "ranger@MY_REALM",
      "password": "ranger_secret",
      "jdbc.driverClassName": "org.apache.hive.jdbc.HiveDriver",
      "jdbc.url": "{hive_url}",
      "commonNameForCertificate": "',
      "policy.download.auth.users": "user",
      "tag.download.auth.users": "user"
    }
  }
}, function(err, status){
  console.log( err ? err.message : "Service Created: " + status)
})
```

    module.exports = (options) ->
      throw Error 'Required Options: username' unless options.username
      throw Error 'Required Options: password' unless options.password
      throw Error 'Required Options: url' unless options.url
      throw Error 'Required Options: service' unless options.service
      throw Error 'Required Options: service.name' unless options.service.name
      @system.execute
        unless_exec: """
        curl --fail -H  "Content-Type: application/json" -k -X GET \
          -u #{options.username}:#{options.password} \
          "#{options.url}/service/public/v2/api/service/name/#{options.service.name}"
        """
        cmd: """
        curl --fail -H "Content-Type: application/json" -k -X POST \
          -d '#{JSON.stringify options.service}' \
          -u #{options.username}:#{options.password} \
          "#{options.url}/service/public/v2/api/service/"
        """
