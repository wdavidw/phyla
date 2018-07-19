
# RYBA Conventions

The purpose of this files is to present all convetions used by developers contributing
to RYBA. not respecting convention can lead to modifications of the files without warning.

## JAVA Components System Options

### Parameters

All components which use an environment file should use the following variable to set system
options. Ryba will render variables based on this variable

Example 1
```json
  opts = {
    "base": "",
    "jvm": {
      "+XX:MaxNewSize=": "200m"
    },
    "java_properties": {
      "krb5.sun.debug": "false"
    }
  }
```

For heapszie and newsize, instead of using the opts property, administrators can use directly the `heapsize` and `newsize`
properties.
Example 1
```json
  options = {
    "heapsize": "1024m",
    "newsize": "200m",
    "opts": {
      "base": "",
      "jvm": {
        "+XX:MaxNewSize=": "200m"
      },
      "java_properties": {
        "krb5.sun.debug": "false"
      }
    }
  }
  
```

### Test

You should test that your properties value are semantically correct. 
See ryba/hadoop/yarn_nm/test.coffee for an example.
