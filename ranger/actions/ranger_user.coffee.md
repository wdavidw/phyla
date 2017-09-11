
# Ranger User

* `password` (string)
  Ranger Administrator password.
* `url` (string)   
  Policy Manager External URL ("POLICY\_MGR\_URL").
* `username` (string)
  Ranger Administrator username.
* `user` (object)   
  User to be created.
* `user.userSource` (boolean)   
  Whether the user is internal (false) or external (true).

## Exemple

```js
nikita
.ranger_user({
  "username": 'ranger_username',
  "password": 'ranger_secret',
  "url": "http://ranger.policy.manager",
  "user": {
    "name": 'hbase',
    "firstName": '',
    "lastName": 'hadoop',
    "emailAddress": 'hbase@hadoop.ryba',
    "password": 'hbase123',
    'userSource': 1,
    'userRoleList': ['ROLE_USER'],
    'groups': [],
    'status': 1
  }
}, function(err, status){
  console.log( err ? err.message : 'User Created: ' + status)
})
```

    module.exports = (options) ->
      throw Error 'Required Options: username' unless options.username
      throw Error 'Required Options: password' unless options.password
      throw Error 'Required Options: url' unless options.url
      throw Error 'Required Options: user' unless options.user
      throw Error 'Required Options: user.name' unless options.user.name
      options.user.userSource = unless options.user.userSource then 0 else 1
      @system.execute
        cmd: """
        curl --fail -H "Content-Type: application/json"   -k -X POST \
          -d '#{JSON.stringify options.user}' \
          -u #{options.username}:#{options.password} \
          "#{options.url}/service/xusers/secure/users"
        """
        unless_exec: if options.user.userSource is 0
        then """
        curl --fail -H "Content-Type: application/json"   -k -X GET \
          -u #{options.username}:#{options.password} \
          "#{options.url}/service/users/profile"
        """
        else """
        curl --fail -H "Content-Type: application/json"   -k -X GET \
          -u #{options.username}:#{options.password} \
          "#{options.url}/service/xusers/users/userName/#{options.user.name}"
        """
