# Kafka development environment

A complete local Kafka stack: three Apache Kafka 4.4.0 brokers with combined KRaft controllers, Kafbat UI, Kafka Connect, and the Karapace schema registry. ZooKeeper is not required. Allow roughly 4 GB of Docker memory for this stack, plus memory for your applications.

## Launch and connect

Run `./start.sh` from this folder. It creates a private `.env` with a random cluster ID and `DEVELOPER_PASSWORD`, initializes volume ownership, and waits for all six services. The optional `init` tools container exits after fixing permissions. The administrator username is **developer** throughout the stack.

| Component | From your host | From a container on `dev-services` |
| --- | --- | --- |
| Kafka bootstrap servers | `localhost:9092,localhost:9093,localhost:9094` | `kafka:9092,kafka-2:9092,kafka-3:9092` |
| Kafbat UI | http://localhost:8090 | `http://kafka-ui:8080` |
| Schema registry | http://localhost:18081 | `http://schema-registry:8081` |
| Kafka Connect REST API | http://localhost:18083 | `http://kafka-connect:8083` |

Kafka clients use `security.protocol=SASL_PLAINTEXT`, `sasl.mechanism=PLAIN`, username `developer`, and the password from `.env`. The UI uses a login form. Schema Registry and Connect use HTTP Basic authentication with the same account; the UI is preconfigured for both. Kafka's developer principal is a superuser, Schema Registry grants full read/write permissions, and Connect permits full REST administration.

Host and Docker bootstrap addresses are intentionally different: Kafka returns advertised broker addresses after bootstrap. Do not use host `localhost` addresses from your application container. Port overrides in `.env` update the external advertisements automatically. These advertisements target localhost, so this setup is for applications on the same machine.

From a language environment folder, attach its container with:

```sh
docker network connect dev-services "$(docker compose ps -q dev)"
```

Repeat after recreating the development container, or declare the shared external network in its Compose configuration.

## Topics and messages

Run from this folder. An authenticated client properties file is generated inside every broker at `/tmp/client.properties`; passwords are not printed by the scripts.

```sh
# Create an explicitly managed, replicated topic:
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server kafka:9092 --command-config /tmp/client.properties \
  --create --topic orders --partitions 3 --replication-factor 3

# Interactive producer; type one message per line, Ctrl-D to finish:
docker compose exec kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server kafka:9092 --producer.config /tmp/client.properties \
  --producer-property acks=all --topic orders

# Consumer; Ctrl-C to finish:
docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server kafka:9092 --consumer.config /tmp/client.properties \
  --topic orders --group orders-reader --from-beginning

# Describe replicas and in-sync replicas:
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server kafka:9092 --command-config /tmp/client.properties \
  --describe --topic orders

# Full API, UI, message and connector verification:
./smoke-test.sh
```

Topic auto-creation is disabled. Default topics use three partitions and replication factor 3, with minimum in-sync replicas 2. Producers using `acks=all` can continue after one broker fails; losing two brokers prevents quorum progress. Logs retain messages for seven days unless a topic overrides retention. Use the UI for topics, messages, consumer groups, schemas and connectors.

## .NET application settings

Install the `Confluent.Kafka` package in your application. Read the password from your application's secrets/environment settings, rather than committing it to source code:

```csharp
using Confluent.Kafka;

var config = new ProducerConfig
{
    BootstrapServers = "kafka:9092,kafka-2:9092,kafka-3:9092",
    SecurityProtocol = SecurityProtocol.SaslPlaintext,
    SaslMechanism = SaslMechanism.Plain,
    SaslUsername = "developer",
    SaslPassword = Environment.GetEnvironmentVariable("KAFKA_PASSWORD"),
    Acks = Acks.All
};
```

For an application running directly on your host, use the localhost bootstrap list from the table. Consumer configuration uses the same security settings plus a `GroupId`.

## Schemas and connectors

Karapace exposes a Confluent-compatible schema-registry API for Avro, JSON Schema and Protobuf. Configure your serializer with the schema-registry URL from the table and HTTP Basic credentials. Schemas are retained in the replicated, compacted `_schemas` Kafka topic.

Kafka Connect runs in distributed mode. Connector configurations, offsets and statuses persist in replicated Kafka topics. Its defaults use JSON converters with schemas disabled; configure the appropriate converters in each connector when using other formats. Schema-registry serializers/converters are not implicitly added to the Kafka Connect classpath.

Place additional connector distributions and all their dependencies in separate subfolders under `plugins/`, then run `docker compose restart kafka-connect`. The official Kafka file source/sink connectors are included. Vendor connectors and schema-aware converters must be installed explicitly and matched to your Kafka/JVM versions. Connector-created local files belong under `/data`, backed by the `connect-data` volume. The smoke test runs a real file-sink task and removes its temporary connector and topic afterward.

## Lifecycle, persistence and credentials

```sh
docker compose ps
docker compose logs -f kafka kafka-2 kafka-3
docker compose stop
./start.sh
# Remove containers, retaining data:
docker compose down
```

Each broker has its own named volume; `/data` in Connect has a separate volume. Removing containers preserves messages, schemas, connector configuration and offsets. Keep `.env` with the volumes: changing `KAFKA_CLUSTER_ID` while reusing broker data prevents startup. `docker compose down --volumes` permanently deletes this environment's data.

To change the developer password, stop the whole stack, update `.env`, then run `./start.sh`. Broker login files and registry/Connect credentials regenerate on startup. Passwords must contain at least 16 characters using letters, digits, underscores and hyphens. Supply other application credentials explicitly if you need multiple users; this template configures only the developer administrator.

Kafka is pinned to 4.4.0; UI and registry default to their current release images. Set the image variables in `.env` to pin their tags/digests. Plan Kafka upgrades using the upstream upgrade guide before changing broker images against existing data. Do not downgrade persistent broker data by simply changing the image tag.

## Security

Use on your local machine only. Host ports bind to `127.0.0.1`. SASL/PLAIN and HTTP Basic authentication here use unencrypted local/Docker connections. Do not expose these ports or attach untrusted workloads to `dev-services`. Combined broker/controller nodes, one Connect worker, one registry, and shared administrator credentials are intended for development on one host; this is not a production deployment.

References: [Apache Kafka Docker configuration](https://kafka.apache.org/44/getting-started/docker/), [Kafka Connect security](https://kafka.apache.org/44/security/security-model-connect/), [Karapace configuration](https://www.karapace.io/docs/configuration/), and [Kafbat UI](https://ui.docs.kafbat.io/).
