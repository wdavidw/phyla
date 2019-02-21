
# DB Admin

This service is a convenient facade towards multiple database services. Multiple
components derived their database configuration from this service. It must be 
provided if you use an external database like MySQL, MariaDB or PostgreSQL

Example:
```
  ryba.db_admin:
    mysql:
      engine: 'mysql'
      hosts: ['master1.ryba','master2.ryba']
      port: '3306'
      admin_username: 'test'
      admin_password: 'test123'
      path: 'mysql'
      jdbc: 'jdbc:mysql://master1.ryba:3306,master2.ryba:3306'
    postgres:
      engine: 'postgresql'
      hosts: ['master1.ryba','master2.ryba']
      port: '3306'
      admin_username: 'test'
      admin_password: 'test123'
      path: 'mysql'
      jdbc: 'jdbc:postgresql://master1.ryba:3306,master2.ryba:3306'
```

If an external database is used, mandatory properties should be hosts,
admin\_username and admin\_password.

`@rybajs/metal/commons/db_admin` constructs the jdbc_url.

`host` is also generated in the final object for legacy compatibility. If the administrators
set it hosts will be constructed on it.

## Source Code

    module.exports =
      deps:
        mariadb: module: 'masson/commons/mariadb/server'
        postres: module: 'masson/commons/postgres/server'
        mysql: module: 'masson/commons/mysql/server'
      configure:
        '@rybajs/tools/db_admin/configure'
