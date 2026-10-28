#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
topic="developer-smoke-$(date +%s)-$$"
message="kafka-smoke-$(date +%s)-$$"
cleanup() {
    docker compose exec -T kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 \
        --command-config /tmp/client.properties --delete --topic "$topic" >/dev/null 2>&1 || true
}
trap cleanup EXIT
docker compose exec -T kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 \
    --command-config /tmp/client.properties --create --topic "$topic" --partitions 3 --replication-factor 3
printf '%s\n' "$message" | docker compose exec -T kafka /opt/kafka/bin/kafka-console-producer.sh \
    --bootstrap-server kafka:9092 --command-config /tmp/client.properties --command-property acks=all --topic "$topic"
result=$(docker compose exec -T kafka /opt/kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server kafka-2:9092 --consumer.config /tmp/client.properties --topic "$topic" --from-beginning --max-messages 1 --timeout-ms 30000)
[[ "$result" == "$message" ]]
echo 'Authenticated produce/consume across brokers passed.'
docker compose exec -T -e "SMOKE_TOPIC=$topic" schema-registry python3 /opt/local/smoke-http.py
docker compose exec -T -e "SMOKE_MESSAGE=$message" kafka-connect bash -ec \
    'grep -Fq "$SMOKE_MESSAGE" /data/developer-smoke.txt; rm /data/developer-smoke.txt'
echo 'Connect sink wrote the Kafka message to its persistent data volume.'
echo 'All Kafka smoke tests passed.'
