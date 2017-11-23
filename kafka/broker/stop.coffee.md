
# Kafka Broker Start

Stop the Kafka Broker.

    module.exports = header: 'Kafka Broker Stop', handler: (options) ->

## Service

You can also stop the server manually with the following commands:

```
service kafka-broker stop
systemctl stop kafka-broker
su -l kafka -c '/usr/hdp/current/kafka-broker/bin/kafka stop'
```

The file storing the PID is "/var/run/kafka/kafka.pid".

      @service.stop
        header: 'Service'
        name: 'kafka-broker'

## Clean Logs

Remove the "*.log" log files if the property "clean_logs" is
activated.

      @system.execute
        header: 'Clean Logs'
        unless: options.clean_logs
        cmd: 'rm -f /var/log/kafka/*.log'
        code_skipped: 1

## Information

To emtpy a topic, please run on a broker node:

```bash
/usr/hdp/current/kafka-broker/bin/kafka-run-class.sh \
  kafka.admin.DeleteTopicCommand \
  --zookeeper <zookeeper_quorum> \
  --topic <your_topic>
```
