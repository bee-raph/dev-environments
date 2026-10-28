#!/usr/bin/env bash
set -euo pipefail
umask 077
[[ "$DEVELOPER_PASSWORD" =~ ^[A-Za-z0-9_-]{16,}$ ]] || { echo 'DEVELOPER_PASSWORD must have at least 16 letters, digits, underscores or hyphens.' >&2; exit 1; }
cat > /tmp/kafka-jaas.conf <<EOF
KafkaServer {
 org.apache.kafka.common.security.plain.PlainLoginModule required
 username="developer" password="$DEVELOPER_PASSWORD" user_developer="$DEVELOPER_PASSWORD";
};
EOF
cat > /tmp/client.properties <<EOF
security.protocol=SASL_PLAINTEXT
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="developer" password="$DEVELOPER_PASSWORD";
request.timeout.ms=10000
default.api.timeout.ms=20000
EOF
exec /etc/kafka/docker/run
