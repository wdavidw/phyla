
# Kafka Broker Start

Stop the Kafka Broker.

    module.exports = header: 'Kafka Broker Stop', label_true: 'STOPPED', handler: (stop) ->

## Service

You can also stop the server manually with the following commands:

```
service kafka-broker stop
systemctl stop kafka-broker
su -l kafka -c '/usr/hdp/current/kafka-broker/bin/kafka stop'
```

The file storing the PID is "/var/run/kafka/kafka.pid".

      @service.stop
        name: 'kafka-broker'

## Clean Logs

      @call header: 'Clean Logs', label_true: 'CLEANED', ->
        @system.execute
          unless: @config.ryba.clean_logs
          cmd: 'rm /var/log/kafka/*'
          code_skipped: 1

To emtpy a topic, please run on a broker node
```bash
/usr/hdp/current/kafka-broker/bin/kafka-run-class.sh kafka.admin.DeleteTopicCommand \
--topic <your_topic> --zookeeper <zookeeper_quorum>
```
