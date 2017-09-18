
# Ranger Policy

Create a Ranger policy using the [REST API v2](https://cwiki.apache.org/confluence/display/RANGER/Apache+Ranger+0.6+-+REST+APIs+for+Service+Definition%2C+Service+and+Policy+Management#ApacheRanger0.6-RESTAPIsforServiceDefinition,ServiceandPolicyManagement-CreatePolicy)

* `password` (string)
  Ranger Administrator password.
* `url` (string)   
  Policy Manager External URL ("POLICY\_MGR\_URL").
* `username` (string)
  Ranger Administrator username.
* `policy` (object)   
  User to be created.
* `policy.name` (string)   
  Name of the policy, required.

## Exemple

```js
nikita
.ranger_policy({
  "username": 'ranger_username',
  "password": 'ranger_secret',
  "url": "http://ranger.policy.manager",
  "policy": {
    "name": "hive-ranger-plugin-audit",
    "service": "hadoop-ryba-hdfs",
    "description": "Hive Ranger Plugin audit log policy",
    "repositoryType": "hdfs",
    "isEnabled": true,
    "isAuditEnabled": true,
    "resources": {
      "path": {
        "isRecursive": "true",
        "values": ["/ranger/audit/hiveServer2"],
        "isExcludes": false
      }
    },
    "policyItems": [{
      "users": ["hive"],
      "groups": [],
      "delegateAdmin": true,
      "accesses": [{
        "isAllowed": true,
        "type": "read"
      },{
        "isAllowed": true,
        "type": "write"
      },{
        "isAllowed": true,
        "type": "execute"
      }],
      "conditions": []
    }]
  }
}, function(err, status){
  console.log( err ? err.message : "Policy Created: " + status)
})
```

    module.exports = (options) ->
      throw Error 'Required Options: username' unless options.username
      throw Error 'Required Options: password' unless options.password
      throw Error 'Required Options: url' unless options.url
      throw Error 'Required Options: policy' unless options.policy
      throw Error 'Required Options: policy.name' unless options.policy.name
      throw Error 'Required Options: policy.service' unless options.policy.service
      @system.execute
        cmd: """
        curl --fail -H "Content-Type: application/json" -k -X POST \
          -d '#{JSON.stringify options.policy}' \
          -u #{options.username}:#{options.password} \
          "#{options.url}/service/public/v2/api/policy"
        """
        unless_exec: """
        curl --fail -H "Content-Type: application/json" -k -X GET  \
          -u #{options.username}:#{options.password} \
          "#{options.url}/service/public/v2/api/service/#{options.policy.service}/policy/#{options.policy.name}"
        """
        code_skippe: 22
