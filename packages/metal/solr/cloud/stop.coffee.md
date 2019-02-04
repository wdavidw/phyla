# Service Solr Stop
Stop the solr service server. You can also stop the server
manually with the following command:

```
service solr stop
```


    module.exports = header: 'Solr Cloud Stop', handler: (options)->

## Service

      @service.stop
        name: 'solr'

## Clean Logs

      @system.execute
        header: 'Clean Logs'
        if: options.clean_logs
        cmd: 'rm /var/log/solr/*'
        code_skipped: 1
