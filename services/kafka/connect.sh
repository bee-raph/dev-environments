#!/usr/bin/env bash
set -euo pipefail
umask 077
cat > /tmp/connect-users.properties <<EOF
developer=$DEVELOPER_PASSWORD
EOF
cat > /tmp/connect-jaas.conf <<EOF
KafkaConnect {
 org.apache.kafka.connect.rest.basic.auth.extension.PropertyFileLoginModule required file="/tmp/connect-users.properties";
};
EOF
cat > /tmp/connect.properties <<EOF
bootstrap.servers=kafka:9092,kafka-2:9092,kafka-3:9092
group.id=local-connect
config.storage.topic=_connect-configs
offset.storage.topic=_connect-offsets
status.storage.topic=_connect-status
config.storage.replication.factor=3
offset.storage.replication.factor=3
status.storage.replication.factor=3
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=false
value.converter.schemas.enable=false
listeners=http://0.0.0.0:8083
rest.advertised.host.name=kafka-connect
rest.advertised.port=8083
rest.extension.classes=org.apache.kafka.connect.rest.basic.auth.extension.BasicAuthSecurityRestExtension
plugin.path=/opt/kafka/libs,/opt/kafka/plugins
connector.client.config.override.policy=All
offset.flush.interval.ms=10000
EOF
for prefix in '' 'producer.' 'consumer.' 'admin.'; do
    cat >> /tmp/connect.properties <<EOF
${prefix}security.protocol=SASL_PLAINTEXT
${prefix}sasl.mechanism=PLAIN
${prefix}sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="developer" password="$DEVELOPER_PASSWORD";
EOF
done
export KAFKA_OPTS='-Djava.security.auth.login.config=/tmp/connect-jaas.conf'
exec /opt/kafka/bin/connect-distributed.sh /tmp/connect.properties
