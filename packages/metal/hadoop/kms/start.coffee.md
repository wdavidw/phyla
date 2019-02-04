
# Hadoop KMS Start

    module.exports = header: 'Hadoop KMS Start', handler: ->
      console.log 'TODO: KMS Start'

## Service

You can also start the server manually with the following two commands:

```
system hadoop-kms start
systemctl start hadoop-kms
su -l hdfs -c "export HADOOP_LIBEXEC_DIR=/usr/hdp/current/hadoop-client/libexec && export KMS_CONFIG=/etc/hadoop-kms/conf && export CATALINA_PID=/var/run/hadoop-kms && /usr/hdp/current/hadoop-kms/sbin/kms.sh start"
```

      @service.start
        name: 'hadoop-kms'
