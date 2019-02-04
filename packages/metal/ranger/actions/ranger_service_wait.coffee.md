
# Ranger Policy

Wait for a Ranger Service (repository) to be created using the [REST API v2](https://cwiki.apache.org/confluence/display/RANGER/Apache+Ranger+0.6+-+REST+APIs+for+Service+Definition%2C+Service+and+Policy+Management#ApacheRanger0.6-RESTAPIsforServiceDefinition,ServiceandPolicyManagement-CreatePolicy)

* `password` (string)
  Ranger Administrator password.
* `url` (string)   
  Policy Manager External URL ("POLICY\_MGR\_URL").
* `username` (string)
  Ranger Administrator username.
* `service` (string)   
  The service (repository) name to wait for.


## Exemple

```js
nikita
.ranger_policy({
  "username": 'ranger_username',
  "password": 'ranger_secret',
  "url": "http://ranger.policy.manager",
  "rservice": 'hadoop-ryba-hbase'
}, function(err, status){
  console.log( err ? err.message : "Policy Created: " + status)
})
```

    module.exports = ({options}) ->
      throw Error 'Required Options: username' unless options.username
      throw Error 'Required Options: password' unless options.password
      throw Error 'Required Options: url' unless options.url
      throw Error 'Required Options: service' unless options.service
      @wait.execute
        cmd: """
        curl --fail -H \"Content-Type: application/json\" -k -X GET  \
        -u #{options.username}:#{options.password} \
        \"#{options.url}/service/public/v2/api/service/name/#{options.service}\"
        """
        code_skipped: 22
